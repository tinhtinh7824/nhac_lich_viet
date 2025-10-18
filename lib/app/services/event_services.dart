// START REPLACE app/services/event_services.dart
import 'dart:async';
import 'dart:convert';
import 'dart:isolate'; // Import Isolate
import 'package:flutter/foundation.dart';
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/data/models/custom_reminder_config.dart';
import 'package:nhac_lich_viet/app/data/providers/api_provider.dart';
import 'package:nhac_lich_viet/app/data/providers/database_provider.dart';
import 'package:nhac_lich_viet/app/data/providers/storage_provider.dart';
import 'package:nhac_lich_viet/app/services/notification_service.dart'; // *** THÊM IMPORT ***
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:nhac_lich_viet/app/utils/lunar_utils.dart';
import 'package:nhac_lich_viet/app/utils/vietnamese_text_utils.dart';
import 'package:nhac_lich_viet/app/services/lunar_service.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';

// --- Isolate Calculation Input ---
class _MonthCalculationInput {
  final int year;
  final int month;
  final List<Event> allEvents;

  _MonthCalculationInput(this.year, this.month, this.allEvents);
}

class _SearchIndexEntry {
  final String normalizedTitle;
  final String abbreviation;
  final int updatedAtMs;

  const _SearchIndexEntry({
    required this.normalizedTitle,
    required this.abbreviation,
    required this.updatedAtMs,
  });
}

/// Service quản lý dữ liệu sự kiện (cả hệ thống và người dùng)
class EventServices extends GetxService {
  // Constants
  static const String _eventBoxName = 'events_box_v1';
  static const String _eventSettingsBoxName = 'event_user_settings_v2';
  static const String _monthlyEventCacheBoxName = 'monthly_event_cache_box123';
  static const String _logTag = 'EventServices';

  // Providers
  final DatabaseProvider _databaseProvider = Get.find<DatabaseProvider>();
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageProvider _storageProvider = Get.find<StorageProvider>();
  NotificationService get _notificationService =>
      Get.find<NotificationService>();

  // Hive Boxes
  late final Box<Event> _eventBox;
  late final Box _eventSettingsBox; // Change to dynamic box
  late final Box<String> _monthlyEventCacheBox;

  // UUID generator
  final Uuid _uuid = const Uuid();

  // Stream controller
  final _eventStreamController = BehaviorSubject<bool>.seeded(false);
  Stream<bool> get eventsStream => _eventStreamController.stream;

  // Cache Mechanism
  final Map<String, bool> _isCalculatingMonth = {};
  final Map<String, _SearchIndexEntry> _searchIndexCache = {};

  @override
  void onInit() {
    super.onInit();
    LoggerUtils.debug('EventServices onInit');
  }

  @override
  void onClose() {
    _eventStreamController.close();
    super.onClose();
  }

  Future<EventServices> init() async {
    LoggerUtils.debug('Initializing EventServices...');
    
    // Removed - not needed with current re-schedule logic
    
    try {
      _eventBox = await _databaseProvider.openBox<Event>(_eventBoxName);
      _eventSettingsBox = await _databaseProvider
          .openBox(_eventSettingsBoxName); // Open as dynamic box
      _monthlyEventCacheBox =
          await _databaseProvider.openBox<String>(_monthlyEventCacheBoxName);
      LoggerUtils.debug('Hive boxes opened successfully.');

      // Debug: Check user settings in box at startup
      final allUserSettings = _eventSettingsBox.keys.toList();
      LoggerUtils.info(
          'APP STARTUP: Found ${allUserSettings.length} user settings in box: ${allUserSettings.take(5).toList()}');
      
      // Fetch events from API first, then migrate if needed
      fetchAllEventsFromApi().then((_) async {
        LoggerUtils.debug('Initial API fetch completed.');
        
        // Migrate cached events AFTER API merge to fix any data issues
        await _migrateEventDataIfNeeded();
        
        // Re-schedule all system event notifications on app startup
        await _rescheduleAllSystemEventNotifications();
        
        _notifyListeners();
      }).catchError((e, stackTrace) {
        LoggerUtils.error('Initial API fetch failed in init', e, stackTrace);
      });
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Failed to initialize EventServices or open boxes', e, stackTrace);
      rethrow;
    }
    LoggerUtils.debug('EventServices initialized.');
    return this;
  }

  /// Migrate cached events to ensure they have all required fields
  /// This handles app updates where new fields are added to the Event model
  Future<void> _migrateEventDataIfNeeded() async {
    try {
      // Force migration for this update to fix notification issues
      // Remove this check after a few app versions
      final migrationKey = 'event_migration_v3_notification_fix';
      final migrationDone = _storageProvider.getBool(migrationKey) ?? false;
      
      if (migrationDone) {
        LoggerUtils.info('Event notification migration v3 already completed, skipping');
        return;
      }
      
      LoggerUtils.info('Starting event notification migration v3 to fix prefix and reminder issues...');
      
      // Get all cached events
      final allEvents = _eventBox.values.toList();
      if (allEvents.isEmpty) {
        LoggerUtils.info('No cached events to migrate');
        return;
      }
      
      int migratedCount = 0;
      final Map<String, Event> eventsToUpdate = {};
      
      for (final event in allEvents) {
        bool needsMigration = false;
        Event migratedEvent = event;
        
        // Check and migrate SimpleNotificationConfig if needed
        if (event.simpleNotificationConfig != null) {
          final config = event.simpleNotificationConfig!;
          
          // Fix common migration issues
          final validatedDaysBefore = <int>[];
          bool configNeedsFix = false;
          
          for (final value in config.notifyDaysBefore) {
            // Common issue: value = 1 (meant to be 1 day = 1440 minutes)
            if (value == 1) {
              // This was likely meant to be 1 day, not 1 minute
              validatedDaysBefore.add(1440); // 1 day in minutes
              configNeedsFix = true;
              LoggerUtils.info('Fixed reminder: 1 minute -> 1 day (1440 minutes) for event ${event.id}');
            } else if (value == 3) {
              // 3 days
              validatedDaysBefore.add(4320); // 3 days in minutes
              configNeedsFix = true;
              LoggerUtils.info('Fixed reminder: 3 minutes -> 3 days (4320 minutes) for event ${event.id}');
            } else if (value == 5) {
              // 5 days
              validatedDaysBefore.add(7200); // 5 days in minutes
              configNeedsFix = true;
              LoggerUtils.info('Fixed reminder: 5 minutes -> 5 days (7200 minutes) for event ${event.id}');
            } else if (value == 7) {
              // 1 week
              validatedDaysBefore.add(10080); // 7 days in minutes
              configNeedsFix = true;
              LoggerUtils.info('Fixed reminder: 7 minutes -> 1 week (10080 minutes) for event ${event.id}');
            } else if (value == 14) {
              // 2 weeks
              validatedDaysBefore.add(20160); // 14 days in minutes
              configNeedsFix = true;
              LoggerUtils.info('Fixed reminder: 14 minutes -> 2 weeks (20160 minutes) for event ${event.id}');
            } else if (value >= 0 && value <= 43200) {
              // Valid minute value, keep as is
              validatedDaysBefore.add(value);
            } else {
              // Invalid value, try to fix
              LoggerUtils.warning('Event ${event.id} has invalid reminder value: $value minutes');
              final days = (value / 1440).round();
              if (days <= 30) {
                validatedDaysBefore.add(days * 1440);
                configNeedsFix = true;
              }
            }
          }
          
          if (configNeedsFix || validatedDaysBefore.length != config.notifyDaysBefore.length) {
            needsMigration = true;
            migratedEvent = migratedEvent.copyWith(
              simpleNotificationConfig: config.copyWith(
                notifyDaysBefore: validatedDaysBefore,
              ),
            );
            LoggerUtils.info('Migrated notification config for event "${event.title}": ${config.notifyDaysBefore} -> $validatedDaysBefore');
          }
          
          // Ensure notifyTime has valid format
          if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(config.notifyTime)) {
            needsMigration = true;
            migratedEvent = migratedEvent.copyWith(
              simpleNotificationConfig: config.copyWith(
                notifyTime: "06:30", // Default to 6:30 AM
              ),
            );
          }
        }
        
        // Check customReminders for migration needs
        if (event.customReminders != null && event.customReminders!.isNotEmpty) {
          final validatedReminders = <CustomReminderConfig>[];
          bool remindersChanged = false;
          
          for (final reminder in event.customReminders!) {
            // Validate reminder based on type
            if (reminder.type == CustomReminderType.countdown) {
              // Validate countdown hours and minutes
              final hours = reminder.countdownHours ?? 0;
              final minutes = reminder.countdownMinutes ?? 0;
              final totalMinutes = hours * 60 + minutes;
              
              if (totalMinutes >= 0 && totalMinutes <= 43200) { // Max 30 days
                validatedReminders.add(reminder);
              } else {
                remindersChanged = true;
                LoggerUtils.warning('Event ${event.id} has invalid countdown reminder: $hours hours, $minutes minutes');
                // Try to fix by capping at 30 days
                if (totalMinutes > 43200) {
                  validatedReminders.add(CustomReminderConfig(
                    id: reminder.id,
                    type: CustomReminderType.countdown,
                    countdownHours: 720, // 30 days
                    countdownMinutes: 0,
                  ));
                }
              }
            } else if (reminder.type == CustomReminderType.specificDate) {
              // Validate specific date is in the future or near future
              if (reminder.specificDateTime != null) {
                validatedReminders.add(reminder);
              } else {
                remindersChanged = true;
                LoggerUtils.warning('Event ${event.id} has specificDate reminder with null date');
              }
            }
          }
          
          if (remindersChanged) {
            needsMigration = true;
            migratedEvent = migratedEvent.copyWith(
              customReminders: validatedReminders,
            );
          }
        }
        
        // Migrate template events to current year if needed
        if (event.eventDate.year < 2020 && event.eventType == EventTypeEnum.system_event.value) {
          needsMigration = true;
          migratedEvent = _convertTemplateEventToCurrentYear(migratedEvent);
          LoggerUtils.info('Migrated template event "${event.title}" from year ${event.eventDate.year} to current year');
        }
        
        // Store migrated event for batch update
        if (needsMigration) {
          eventsToUpdate[migratedEvent.id] = migratedEvent;
          migratedCount++;
        }
      }
      
      // Batch update migrated events
      if (eventsToUpdate.isNotEmpty) {
        await _eventBox.putAll(eventsToUpdate);
        LoggerUtils.info('Successfully migrated $migratedCount events with updated fields');
        
        // Clear all caches to ensure UI refreshes with migrated data
        await _monthlyEventCacheBox.clear();
        LoggerUtils.info('Cleared monthly cache after migration');
      } else {
        LoggerUtils.info('No events needed migration');
      }
      
      // Mark migration as complete
      await _storageProvider.setBool(migrationKey, true);
      LoggerUtils.info('Event notification migration v3 marked as complete');
      
      // Force re-schedule all notifications after migration to apply fixes
      if (migratedCount > 0) {
        LoggerUtils.info('Re-scheduling all notifications after migration...');
        await _rescheduleAllSystemEventNotifications();
      }
      
    } catch (e, stackTrace) {
      LoggerUtils.error('Error during event data migration', e, stackTrace);
      // Don't rethrow - allow app to continue even if migration fails
    }
  }

  Future<List<Event>> fetchAllEventsFromApi() async {
    try {
      LoggerUtils.debug('Fetching all events from API...');
      final response = await _apiProvider.get(
        '/events',
        queryParameters: {'limit': '5000'},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final eventsData = response.data['responseObject']['events'] as List?;
        if (eventsData == null) {
          LoggerUtils.warning(
              'API response is successful but event data is null.');
          return getAllEvents();
        }

        final List<Event> apiEvents =
            eventsData.map((e) => Event.fromJson(e)).toList();
        LoggerUtils.debug('Fetched ${apiEvents.length} events from API.');

        // Debug: Log first few events to check their dates
        if (apiEvents.isNotEmpty) {
          LoggerUtils.info('========== API EVENTS DATE CHECK ==========');
          for (var i = 0; i < apiEvents.length.clamp(0, 5); i++) {
            final event = apiEvents[i];
            LoggerUtils.info(
                'Event ${i + 1}: "${event.title}" - Date: ${event.eventDate.toIso8601String()} '
                '(Year: ${event.eventDate.year}) - RepeatType: ${event.repeatType}');
          }

          // Check how many events are from 1900
          final events1900 =
              apiEvents.where((e) => e.eventDate.year == 1900).length;
          final events2025 =
              apiEvents.where((e) => e.eventDate.year == 2025).length;
          final eventsCurrentYear = apiEvents
              .where((e) => e.eventDate.year == DateTime.now().year)
              .length;

          LoggerUtils.info('Events from year 1900: $events1900');
          LoggerUtils.info('Events from year 2025: $events2025');
          LoggerUtils.info(
              'Events from current year (${DateTime.now().year}): $eventsCurrentYear');
          LoggerUtils.info('==========================================');
        }

        await _mergeApiEvents(apiEvents); // <--- MERGE AND CLEANUP HAPPENS HERE
        LoggerUtils.debug('Finished merging and cleaning API events.');
        _notifyListeners(); // Notify after merge & cleanup
        return getAllEvents(); // Return current state after merge
      } else {
        LoggerUtils.warning(
            'API returned unsuccessful response: ${response.statusCode}');
        return getAllEvents(); // Return local data on API failure
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Error fetching events from API', e, stackTrace);
      return getAllEvents(); // Return local data on error
    }
  }

  // --- MODIFIED ---
  Future<void> _mergeApiEvents(List<Event> apiEvents) async {
    // Check if boxes are initialized before proceeding
    if (!Hive.isBoxOpen(_eventBoxName) || !Hive.isBoxOpen(_eventSettingsBoxName)) {
      LoggerUtils.warning('Boxes not initialized yet, skipping API merge');
      return;
    }

    final Map<String, Event> eventsToPut = {};
    final Set<String> affectedMonthKeys = {};
    bool needsRecurringCacheClear = false;

    // 1. Identify System Event IDs from API
    final Set<String> apiSystemEventIds = apiEvents
        .where((e) => e.eventType == EventTypeEnum.system_event.value)
        .map((e) => e.id)
        .toSet();

    LoggerUtils.info('API returned ${apiEvents.length} total events, '
        '${apiSystemEventIds.length} are system events');

    // 2. Convert template events from old years to current year if needed
    final List<Event> processedApiEvents = [];
    final currentYear = DateTime.now().year;

    for (final apiEvent in apiEvents) {
      // Convert events from any year before 2020 to current year (likely templates)
      if (apiEvent.eventDate.year < 2020) {
        final convertedEvent = _convertTemplateEventToCurrentYear(apiEvent);
        processedApiEvents.add(convertedEvent);
        LoggerUtils.debug(
            'Converted template event "${apiEvent.title}" from ${apiEvent.eventDate.year} to ${convertedEvent.eventDate.year}');
      } else {
        processedApiEvents.add(apiEvent);
      }
    }

    // 3. Merge API data into local storage
    for (final apiEvent in processedApiEvents) {
      LoggerUtils.debug('Processing API event: id=${apiEvent.id}, '
          'type=${apiEvent.eventType}, title=${apiEvent.title}');

      if (apiEvent.eventType == EventTypeEnum.system_event.value) {
        final existingEvent = _eventBox.get(apiEvent.id);
        final dynamic rawSettings = _eventSettingsBox.get(apiEvent.id);
        final Map<String, dynamic> userSettings = rawSettings is Map
            ? Map<String, dynamic>.from(rawSettings as Map)
            : <String, dynamic>{};

        if (userSettings['isDeleted'] == true) {
          LoggerUtils.debug(
              'System event ${apiEvent.id} is marked deleted by user. Skipping re-add.');
          if (existingEvent != null) {
            await _eventBox.delete(apiEvent.id);
          }
          continue;
        }

        LoggerUtils.debug(
            'Event ${apiEvent.id}: userSettings from box = ${userSettings.isNotEmpty ? userSettings.keys.toList() : "EMPTY"}');
        final bool userNotifySetting =
            userSettings['isNotify'] ?? apiEvent.isNotify;
        final SimpleNotificationConfig? userNotificationConfig =
            userSettings['simpleNotificationConfig'] != null
                ? SimpleNotificationConfig.fromJson(Map<String, dynamic>.from(
                    userSettings['simpleNotificationConfig']), isFromAPI: false)
                : apiEvent.simpleNotificationConfig;

        final List<CustomReminderConfig>? userCustomReminders =
            userSettings['customReminders'] != null
                ? (userSettings['customReminders'] as List)
                    .map((item) => CustomReminderConfig.fromJson(
                        Map<String, dynamic>.from(item)))
                    .toList()
                : apiEvent.customReminders;

        final updatedEvent = apiEvent.copyWith(
          isNotify: userNotifySetting,
          simpleNotificationConfig: userNotificationConfig,
          customReminders: userCustomReminders,
          createdAt: existingEvent?.createdAt ??
              apiEvent.createdAt, // Preserve original create date if exists
          updatedAt: apiEvent.updatedAt,
        );

        // Check if update is needed or if it's a new event
        bool needsUpdate = false;

        if (existingEvent == null) {
          // New event from API
          needsUpdate = true;
          LoggerUtils.debug(
              'System event ${apiEvent.id} is new, will be added');
        } else {
          // Check if API event has changes
          needsUpdate = existingEvent.title != apiEvent.title ||
              existingEvent.description != apiEvent.description ||
              existingEvent.detail != apiEvent.detail ||
              existingEvent.eventDate != apiEvent.eventDate ||
              existingEvent.eventTime != apiEvent.eventTime ||
              existingEvent.categoryId != apiEvent.categoryId ||
              existingEvent.iconUrl != apiEvent.iconUrl ||
              existingEvent.bannerUrl != apiEvent.bannerUrl ||
              existingEvent.isLunar != apiEvent.isLunar ||
              existingEvent.originalLunarDate != apiEvent.originalLunarDate ||
              existingEvent.repeatType != apiEvent.repeatType ||
              existingEvent.showOnCalendar != apiEvent.showOnCalendar;
          
          // Also check notification config changes IF user hasn't customized
          if (!needsUpdate && userSettings.isEmpty) {
            // User hasn't customized, so check if server default changed
            final existingConfig = existingEvent.simpleNotificationConfig;
            final apiConfig = apiEvent.simpleNotificationConfig;
            
            if (existingConfig != null && apiConfig != null) {
              needsUpdate = existingConfig.notifyTime != apiConfig.notifyTime ||
                  existingConfig.notifyOnDay != apiConfig.notifyOnDay ||
                  existingConfig.notifyDaysBefore.toString() != apiConfig.notifyDaysBefore.toString();
              
              if (needsUpdate) {
                LoggerUtils.debug('System event ${apiEvent.id} has notification config changes from server');
              }
            } else if (existingConfig != apiConfig) {
              // One is null, other isn't
              needsUpdate = true;
            }
          }

          if (needsUpdate) {
            LoggerUtils.debug(
                'System event ${apiEvent.id} has content changes, will update while preserving user settings');
          }
        }

        if (needsUpdate) {
          eventsToPut[updatedEvent.id] = updatedEvent;
          affectedMonthKeys.add(_formatMonthKey(updatedEvent.eventDate));
          if (updatedEvent.repeatType != 'Không lặp lại' &&
              updatedEvent.repeatType.isNotEmpty) {
            needsRecurringCacheClear = true;
          }
          // Schedule/cancel notification for the updated/new event
          await _scheduleOrCancelEventNotification(updatedEvent);

          LoggerUtils.debug(
              'System event ${apiEvent.id} updated. User notification settings preserved: '
              'isNotify=${updatedEvent.isNotify}, hasCustomReminders=${updatedEvent.customReminders?.isNotEmpty ?? false}');
        } else if (existingEvent != null) {
          // IMPORTANT: Even if no content changes, we still need to ensure
          // user notification settings are applied to the event in the box
          final bool hasUserSettings = userSettings.isNotEmpty;
          final bool existingEventHasUserSettings =
              existingEvent.isNotify != apiEvent.isNotify ||
                  (existingEvent.simpleNotificationConfig != null &&
                      apiEvent.simpleNotificationConfig == null) ||
                  (existingEvent.customReminders?.isNotEmpty ?? false);

          if (hasUserSettings && !existingEventHasUserSettings) {
            // User has settings but existing event doesn't have them applied
            eventsToPut[updatedEvent.id] = updatedEvent;
            await _scheduleOrCancelEventNotification(updatedEvent);
            LoggerUtils.debug(
                'System event ${apiEvent.id} unchanged but applying user settings: '
                'isNotify=${updatedEvent.isNotify}, hasCustomReminders=${updatedEvent.customReminders?.isNotEmpty ?? false}');
          } else {
            // Check if this is a converted template event that needs to be saved
            if (apiEvent.eventDate.year != existingEvent.eventDate.year &&
                updatedEvent.eventDate.year >= 2020) {
              // Event year has changed (converted from template), force update
              eventsToPut[updatedEvent.id] = updatedEvent;
              await _scheduleOrCancelEventNotification(updatedEvent);
              LoggerUtils.info(
                  'Template event ${apiEvent.id} converted from year ${existingEvent.eventDate.year} to ${updatedEvent.eventDate.year}. Force update.');
            } else {
              LoggerUtils.debug(
                  'System event ${apiEvent.id} unchanged. User settings already applied: '
                  'isNotify=${existingEvent.isNotify}, hasCustomReminders=${existingEvent.customReminders?.isNotEmpty ?? false}');
            }
          }
        }
      }
      // Note: User events from API are ignored here, assuming API only sends system events
    }

    // 3. DISABLED: Auto-delete system events not in API response
    // This logic is commented out because it can accidentally delete events
    // when API doesn't return full data (pagination, filters, network issues)
    // This was causing user notification settings to be lost
    /*
    final List<String> localKeys = _eventBox.keys.cast<String>().toList();
    final Set<String> idsToDelete = {};
    for (final key in localKeys) {
      final localEvent = _eventBox.get(key);
      if (localEvent != null &&
          localEvent.eventType == EventTypeEnum.system_event.value &&
          !apiSystemEventIds.contains(localEvent.id)) {
        idsToDelete.add(localEvent.id);
        // Also mark the month of the deleted event for cache clearing
        affectedMonthKeys.add(_formatMonthKey(localEvent.eventDate));
        if (localEvent.repeatType != 'Không lặp lại' &&
            localEvent.repeatType.isNotEmpty) {
          needsRecurringCacheClear = true;
        }
      }
    }

    // 4. Perform Deletion
    if (idsToDelete.isNotEmpty) {
      LoggerUtils.info(
          'Deleting ${idsToDelete.length} outdated system events: ${idsToDelete.join(', ')}');
      for (final id in idsToDelete) {
        await _cancelEventNotification(id);
        await _eventBox.delete(id);
        await _eventSettingsBox.delete(id);
      }
    }
    */

    LoggerUtils.debug(
        'System event deletion disabled to preserve user notification settings. '
        'Manual cleanup may be needed for truly deleted events.');

    // 5. Perform Updates/Additions
    if (eventsToPut.isNotEmpty) {
      await _eventBox.putAll(eventsToPut);
      LoggerUtils.debug(
          'Merged/Updated ${eventsToPut.length} system events into Hive.');
    }

    // 6. Re-schedule all system event notifications after merge
    await _rescheduleAllSystemEventNotifications();
    
    // 7. Clear Cache if necessary
    if (affectedMonthKeys.isNotEmpty) {
      await _clearMonthlyCacheForMonths(affectedMonthKeys);
    }
    if (needsRecurringCacheClear) {
      await _clearAllRecurringCacheInMonthlyBox();
      LoggerUtils.debug(
          'Recurring cache cleared due to API merge or deletions.');
    }
  }
  // --- END MODIFIED ---

  /// Smart iOS-aware notification scheduler with 30-day rolling window
  /// Constants for iOS notification management
  static const int IOS_NOTIFICATION_LIMIT = 64;
  static const int SYSTEM_EVENT_MAX_SLOTS = 50; // Reserve 14 for user events
  static const int SCHEDULE_WINDOW_DAYS = 60; // 60-day rolling window (2 months)
  
  /// Re-schedule all system event notifications with iOS limit awareness
  /// This ensures notifications work properly after API updates or app restart
  Future<void> _rescheduleAllSystemEventNotifications() async {
    try {
      // Check platform
      final bool isIOS = GetPlatform.isIOS;
      
      if (isIOS) {
        LoggerUtils.info('📱 iOS detected - Using smart scheduling with 64 limit');
        await _rescheduleSystemEventsForIOS();
      } else {
        // Android: Skip reschedule on normal launch
        // Notifications persist and are managed by Android OS
        // They are scheduled when events are loaded from API
        final count = _eventBox.values
            .where((e) => e.eventType == EventTypeEnum.system_event.value && e.isNotify)
            .length;
        LoggerUtils.info('🤖 Android: ${count} system events available');
        
        // Note: Notifications are scheduled via loadSystemEventsFromAPI()
        // which calls _scheduleOrCancelEventNotification() for each event
      }
    } catch (e) {
      LoggerUtils.error('Failed to re-schedule system events', e);
    }
  }
  
  /// iOS-specific scheduler with smart rolling window
  Future<void> _rescheduleSystemEventsForIOS() async {
    try {
      final now = DateTime.now();
      
      // Platform-optimized window for best performance
      final windowDays = await _calculateOptimalWindow();
      final cutoffDate = now.add(Duration(days: windowDays));
      
      LoggerUtils.info('📱 iOS Scheduler: Using ${windowDays}-day window (optimized)');
      
      // Get all system events
      final allSystemEvents = _eventBox.values
          .where((e) => e.eventType == EventTypeEnum.system_event.value && e.isNotify)
          .toList();
      
      // Get currently scheduled notifications
      final currentNotifications = await _notificationService.getPendingNotificationRequests();
      final Set<String> scheduledEventIds = {};
      
      // Parse currently scheduled events
      for (final notif in currentNotifications) {
        if (notif.payload != null) {
          try {
            final payload = jsonDecode(notif.payload!);
            final eventId = payload['eventId'] as String?;
            if (eventId != null) {
              scheduledEventIds.add(eventId);
            }
          } catch (e) {
            LoggerUtils.debug('Failed to parse notification payload: $e');
          }
        }
      }
      
      LoggerUtils.info('📊 Currently scheduled: ${scheduledEventIds.length} events');
      
      // Categorize events
      final List<_EventWithPriority> toSchedule = [];
      final List<String> toCancel = [];
      final Set<String> keepScheduled = {};
      
      for (final event in allSystemEvents) {
        final nextOccurrence = _calculateNextOccurrence(event, now);
        if (nextOccurrence == null) continue;
        
        final isScheduled = scheduledEventIds.contains(event.id);
        final isWithinWindow = nextOccurrence.isBefore(cutoffDate);
        final hasExpired = nextOccurrence.isBefore(now);
        
        if (hasExpired && isScheduled) {
          // Expired but still scheduled → Cancel
          toCancel.add(event.id);
        } else if (isWithinWindow && !isScheduled) {
          // Within window but not scheduled → Schedule
          final priority = _calculateEventPriority(event, nextOccurrence);
          toSchedule.add(_EventWithPriority(event, priority, nextOccurrence));
        } else if (isWithinWindow && isScheduled) {
          // Within window and already scheduled → Keep
          keepScheduled.add(event.id);
        } else if (!isWithinWindow && isScheduled) {
          // Outside window but scheduled → Cancel (make room)
          toCancel.add(event.id);
        }
      }
      
      // Sort by priority (higher = more important)
      toSchedule.sort((a, b) => b.priority.compareTo(a.priority));
      
      LoggerUtils.info('📋 Schedule plan: Keep ${keepScheduled.length}, Cancel ${toCancel.length}, Add ${toSchedule.length}');
      
      // Cancel only what needs canceling
      for (final eventId in toCancel) {
        await _notificationService.cancelEventNotification(eventId);
      }
      
      // Calculate available slots
      final usedSlots = keepScheduled.length;
      final availableSlots = SYSTEM_EVENT_MAX_SLOTS - usedSlots;
      
      LoggerUtils.info('📊 Slots: ${usedSlots} used, ${availableSlots} available');
      
      // Schedule new events within available slots
      int scheduledCount = 0;
      for (final item in toSchedule) {
        if (scheduledCount >= availableSlots) {
          LoggerUtils.warning('⚠️ Reached available slots limit. Queuing rest for next refresh.');
          break;
        }
        
        try {
          await _notificationService.scheduleEventNotification(item.event);
          scheduledCount++;
          LoggerUtils.debug('✅ Added: ${item.event.title} (priority: ${item.priority})');
        } catch (e) {
          LoggerUtils.error('Failed to schedule ${item.event.title}', e);
        }
      }
      
      LoggerUtils.info('✅ iOS Smart Schedule complete: ${keepScheduled.length + scheduledCount} total events');
      
      // Save state with next refresh time
      await _saveSchedulingStateV2(
        keepScheduled.toList(),
        toSchedule.skip(scheduledCount).map((e) => e.event.id).toList(),
        windowDays
      );
      
    } catch (e) {
      LoggerUtils.error('Error in iOS smart scheduling', e);
    }
  }
  
  /// Calculate optimal window size - Unified for both platforms
  Future<int> _calculateOptimalWindow() async {
    // OPTIMIZATION: Use fixed 60-day window for both platforms
    // This avoids expensive calculations that cause startup lag
    
    // 60-day window works well because:
    // - Most users have <40 events in 2 months (well under iOS 64-limit)
    // - Covers important monthly events twice
    // - Reduces need for frequent rescheduling
    // - Simple and predictable behavior
    
    return 60; // 2 months for both iOS and Android
    
    // Note: If user has >64 events in 60 days (rare), 
    // the priority system will select most important ones for iOS
  }
  
  /// Calculate event priority (higher = more important)
  int _calculateEventPriority(Event event, DateTime nextOccurrence) {
    int priority = 0;
    
    // Time until event (closer = higher priority)
    final daysUntil = nextOccurrence.difference(DateTime.now()).inDays;
    priority += (100 - daysUntil.clamp(0, 100));
    
    // Has custom config = user configured = important
    if (event.customReminders?.isNotEmpty ?? false) priority += 50;
    if (event.simpleNotificationConfig != null) priority += 30;
    
    // Popular holidays get priority
    if (event.title.contains('Tết')) priority += 40;
    if (event.title.contains('Quốc khánh')) priority += 30;
    if (event.title.contains('Rằm')) priority += 20;
    
    // Lunar events need special attention
    if (event.isLunar) priority += 25;
    
    return priority;
  }
  
  /// Save scheduling state V2 with more info
  Future<void> _saveSchedulingStateV2(
    List<String> scheduledIds,
    List<String> queuedIds,
    int windowDays
  ) async {
    try {
      final state = {
        'lastRefresh': DateTime.now().toIso8601String(),
        'nextRefresh': DateTime.now().add(Duration(days: 7)).toIso8601String(),
        'windowDays': windowDays,
        'scheduledIds': scheduledIds,
        'queuedIds': queuedIds,
        'stats': {
          'scheduled': scheduledIds.length,
          'queued': queuedIds.length,
          'total': scheduledIds.length + queuedIds.length,
        }
      };
      
      await _storageProvider.setString('ios_notification_state_v2', jsonEncode(state));
      LoggerUtils.debug('Saved scheduling state V2');
    } catch (e) {
      LoggerUtils.error('Error saving state V2', e);
    }
  }
  
  // Android doesn't need mass reschedule
  // Each event is scheduled individually via _scheduleOrCancelEventNotification()
  // when added/updated through loadSystemEventsFromAPI() or user actions
  
  /// Calculate next occurrence of an event
  DateTime? _calculateNextOccurrence(Event event, DateTime fromDate) {
    try {
      final eventDate = event.eventDate;
      
      // For non-repeating events
      if (event.repeatType == 'Không lặp lại' || event.repeatType.isEmpty) {
        return eventDate.isAfter(fromDate) ? eventDate : null;
      }
      
      // For yearly events
      if (event.repeatType == 'yearly' || event.repeatType == 'Hằng năm') {
        DateTime nextOccurrence = DateTime(
          fromDate.year,
          eventDate.month,
          eventDate.day,
          eventDate.hour,
          eventDate.minute,
        );
        
        if (nextOccurrence.isBefore(fromDate)) {
          nextOccurrence = DateTime(
            fromDate.year + 1,
            eventDate.month,
            eventDate.day,
            eventDate.hour,
            eventDate.minute,
          );
        }
        
        return nextOccurrence;
      }
      
      // For other repeat types, return next occurrence
      return eventDate.isAfter(fromDate) ? eventDate : null;
      
    } catch (e) {
      LoggerUtils.error('Error calculating next occurrence for ${event.title}', e);
      return null;
    }
  }
  
  /// Save scheduling state for background refresh
  Future<void> _saveSchedulingState(List<Event> scheduled, List<Event> pending) async {
    try {
      final state = {
        'lastScheduled': DateTime.now().toIso8601String(),
        'scheduledCount': scheduled.length,
        'pendingCount': pending.length,
        'scheduledIds': scheduled.map((e) => e.id).toList(),
        'pendingIds': pending.map((e) => e.id).toList(),
      };
      
      await _storageProvider.setString('notification_schedule_state', jsonEncode(state));
      LoggerUtils.debug('Saved scheduling state');
    } catch (e) {
      LoggerUtils.error('Error saving scheduling state', e);
    }
  }
  
  /// Public method for background refresh
  Future<void> refreshNotificationSchedule() async {
    try {
      LoggerUtils.info('🔄 Starting notification schedule refresh...');
      
      // Check last refresh time
      final stateJson = _storageProvider.getString('notification_schedule_state');
      if (stateJson != null) {
        final state = jsonDecode(stateJson);
        final lastScheduled = DateTime.parse(state['lastScheduled']);
        final daysSinceLastRefresh = DateTime.now().difference(lastScheduled).inDays;
        
        LoggerUtils.info('📅 Last refresh: $daysSinceLastRefresh days ago');
        
        // Only refresh if it's been at least 3 days
        if (daysSinceLastRefresh < 3) {
          LoggerUtils.info('⏭️ Skipping refresh - too recent');
          return;
        }
      }
      
      // Perform refresh
      await _rescheduleAllSystemEventNotifications();
      
      LoggerUtils.info('✅ Notification schedule refreshed successfully');
    } catch (e) {
      LoggerUtils.error('Error refreshing notification schedule', e);
    }
  }
  
  // Helper method to convert template events from old years to current/target year
  Event _convertTemplateEventToCurrentYear(Event templateEvent,
      {int? targetYear}) {
    final currentYear = targetYear ?? DateTime.now().year;

    // Only process events from old years (assumed to be templates)
    if (templateEvent.eventDate.year >= 2020) {
      return templateEvent;
    }

    LoggerUtils.debug(
        'Converting template event ${templateEvent.id} from ${templateEvent.eventDate.year} to $currentYear');

    // Calculate the year difference
    final yearDiff = currentYear - templateEvent.eventDate.year;

    // Handle special case for February 29 (leap year)
    int targetDay = templateEvent.eventDate.day;
    if (templateEvent.eventDate.month == 2 &&
        templateEvent.eventDate.day == 29) {
      // Check if target year is a leap year
      final targetYear = templateEvent.eventDate.year + yearDiff;
      final isLeapYear = (targetYear % 4 == 0 && targetYear % 100 != 0) ||
          (targetYear % 400 == 0);
      if (!isLeapYear) {
        // If not a leap year, use February 28
        targetDay = 28;
        LoggerUtils.debug(
            'Adjusted Feb 29 to Feb 28 for non-leap year $targetYear');
      }
    }

    // Create new date by adding the year difference
    final newEventDate = DateTime(
      templateEvent.eventDate.year + yearDiff,
      templateEvent.eventDate.month,
      targetDay,
      templateEvent.eventDate.hour,
      templateEvent.eventDate.minute,
      templateEvent.eventDate.second,
    );

    // For lunar dates, also update the originalLunarDate
    DateTime? newOriginalLunarDate;
    if (templateEvent.isLunar && templateEvent.originalLunarDate != null) {
      newOriginalLunarDate = DateTime(
        templateEvent.originalLunarDate!.year + yearDiff,
        templateEvent.originalLunarDate!.month,
        templateEvent.originalLunarDate!.day,
      );
    }

    // Return a copy with updated dates
    return templateEvent.copyWith(
      eventDate: newEventDate,
      originalLunarDate: newOriginalLunarDate,
    );
  }

  Future<void> saveUserEventSettings(Event event) async {
    if (event.eventType == EventTypeEnum.system_event.value) {
      // Check if settings box is initialized
      if (!Hive.isBoxOpen(_eventSettingsBoxName)) {
        LoggerUtils.warning('Event settings box not initialized, cannot save user settings');
        return;
      }

      try {
        // 1. Save user settings to settings box
        final settingsToSave = {
          'isNotify': event.isNotify,
          'simpleNotificationConfig': event.simpleNotificationConfig?.toJson(),
          'customReminders':
              event.customReminders?.map((e) => e.toJson()).toList(),
        };

        await _eventSettingsBox.put(event.id, settingsToSave);

        // Force flush to disk
        await _eventSettingsBox.flush();

        LoggerUtils.debug(
            'SAVED user settings for ${event.id}: ${settingsToSave.keys.toList()}');

        // Verify save
        final savedSettings = _eventSettingsBox.get(event.id);
        LoggerUtils.debug(
            'VERIFIED saved settings for ${event.id}: ${savedSettings?.keys.toList() ?? "NOT_FOUND"}');

        // Double check: Count total settings in box
        final totalSettings = _eventSettingsBox.keys.length;
        LoggerUtils.debug(
            'TOTAL user settings in box after save: $totalSettings');

        // 2. IMPORTANT: Also update the event in main event box
        // This ensures the event has the latest notification settings
        final existingEvent = _eventBox.get(event.id);
        if (existingEvent != null) {
          // Preserve all existing data, only update notification settings
          final updatedEvent = existingEvent.copyWith(
            isNotify: event.isNotify,
            simpleNotificationConfig: event.simpleNotificationConfig,
            customReminders: event.customReminders,
            updatedAt: DateTime.now(),
          );
          await _eventBox.put(event.id, updatedEvent);
          LoggerUtils.debug(
              'Updated system event ${event.id} in main box with user notification settings');
        }

        // 3. Schedule/cancel notifications
        await _scheduleOrCancelEventNotification(event);

        // 4. Clear cache for the event's month to ensure UI updates
        await _clearMonthlyCacheForDate(event.eventDate);

        LoggerUtils.debug(
            'Saved notification settings for system event: ${event.id} '
            '(isNotify=${event.isNotify}, customReminders=${event.customReminders?.length ?? 0})');

        // 5. Notify listeners to update UI
        _notifyListeners();
      } catch (e, stackTrace) {
        LoggerUtils.error(
            'Error saving settings for event ${event.id}', e, stackTrace);
      }
    }
  }

  Future<Event?> addEvent(Event event) async {
    try {
      final newId = event.id.isEmpty ? _uuid.v4() : event.id;
      final now = DateTime.now();
      // Đảm bảo eventType là user_event nếu không được cung cấp hoặc khác
      final eventType = event.eventType == EventTypeEnum.system_event.value
          ? EventTypeEnum.system_event.value // Giữ nguyên nếu là system event
          : EventTypeEnum.user_event.value; // Mặc định hoặc ép về user event

      final newEvent = event.copyWith(
        id: newId,
        eventType: eventType, // Sử dụng eventType đã xác định
        createdAt: now,
        updatedAt: now,
      );

      await _eventBox.put(newEvent.id, newEvent);
      _searchIndexCache.remove(newEvent.id);
      await _clearMonthlyCacheForDate(newEvent.eventDate);
      if (newEvent.repeatType != 'Không lặp lại' &&
          newEvent.repeatType.isNotEmpty) {
        await _clearAllRecurringCacheInMonthlyBox();
      }

      await _scheduleOrCancelEventNotification(newEvent);

      LoggerUtils.debug('Added new event: ${newEvent.id}');
      _notifyListeners();
      return newEvent;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error adding event', e, stackTrace);
      return null;
    }
  }

  Future<Event?> saveUserEvent(Event event) async {
    try {
      // addEvent sẽ tự xử lý eventType nếu cần
      final newEvent = await addEvent(event);
      return newEvent;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error saving user event', e, stackTrace);
      return null;
    }
  }

  Future<bool> updateEvent(Event event) async {
    try {
      if (!_eventBox.containsKey(event.id)) {
        LoggerUtils.warning('Event not found for update: ${event.id}');
        return false;
      }
      final oldEvent = _eventBox.get(event.id)!;

      // Hủy thông báo cũ TRƯỚC KHI lưu
      await _cancelEventNotification(oldEvent.id);

      final updatedEvent = event.copyWith(updatedAt: DateTime.now());
      await _eventBox.put(event.id, updatedEvent);
      _searchIndexCache.remove(event.id);

      await _clearMonthlyCacheForDate(oldEvent.eventDate);
      if (!_isSameMonth(oldEvent.eventDate, updatedEvent.eventDate)) {
        await _clearMonthlyCacheForDate(updatedEvent.eventDate);
      }

      if (oldEvent.repeatType != updatedEvent.repeatType ||
          !isSameDay(oldEvent.eventDate, updatedEvent.eventDate) ||
          (updatedEvent.repeatType != 'Không lặp lại' &&
              updatedEvent.repeatType.isNotEmpty)) {
        await _clearAllRecurringCacheInMonthlyBox();
        LoggerUtils.debug(
            'Recurring cache cleared due to event update: ${event.id}');
      }

      // Lên lịch/hủy thông báo MỚI SAU KHI lưu
      await _scheduleOrCancelEventNotification(updatedEvent);

      LoggerUtils.debug('Updated event: ${event.id}');
      _notifyListeners();
      return true;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error updating event ${event.id}', e, stackTrace);
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      if (!_eventBox.containsKey(id)) {
        LoggerUtils.warning('Event not found for deletion: $id');
        return false;
      }
      if (!Hive.isBoxOpen(_eventSettingsBoxName)) {
        LoggerUtils.warning('Event settings box not initialized, cannot delete event settings');
        // Still allow deletion of the main event
        final eventToDelete = _eventBox.get(id)!;
        await _cancelEventNotification(eventToDelete.id);
        await _eventBox.delete(id);
        _notifyListeners();
        return true;
      }

      final eventToDelete = _eventBox.get(id)!;

      // Hủy thông báo TRƯỚC KHI xóa
      await _cancelEventNotification(eventToDelete.id);

      LoggerUtils.debug(
          'Deleting event: ${eventToDelete.id} - ${eventToDelete.title}');

      if (eventToDelete.eventType == EventTypeEnum.system_event.value) {
        final dynamic rawSettings = _eventSettingsBox.get(id);
        final Map<String, dynamic> updatedSettings = rawSettings is Map
            ? Map<String, dynamic>.from(rawSettings as Map)
            : <String, dynamic>{};
        updatedSettings['isDeleted'] = true;
        await _eventSettingsBox.put(id, updatedSettings);
      } else {
        await _eventSettingsBox.delete(id);
      }

      await _eventBox.delete(id);
      _searchIndexCache.remove(id);

      await _clearMonthlyCacheForDate(eventToDelete.eventDate);
      if (eventToDelete.repeatType != 'Không lặp lại' &&
          eventToDelete.repeatType.isNotEmpty) {
        await _clearAllRecurringCacheInMonthlyBox();
      }

      LoggerUtils.debug('Deleted event: $id');
      _notifyListeners();
      return true;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error deleting event', e, stackTrace);
      return false;
    }
  }

  List<Event> getAllEvents() {
    try {
      // Check if boxes are initialized before accessing
      if (!Hive.isBoxOpen(_eventBoxName)) {
        LoggerUtils.debug(
            'Event box not initialized yet, returning empty list');
        return [];
      }
      if (!Hive.isBoxOpen(_eventSettingsBoxName)) {
        LoggerUtils.debug(
            'Event settings box not initialized yet, returning empty list');
        return [];
      }
      if (!_eventBox.isOpen) {
        LoggerUtils.warning('Event box is not open, cannot get events.');
        return [];
      }
      final List<Event> events = [];
      for (final event in _eventBox.values) {
        if (event.eventType == EventTypeEnum.system_event.value) {
          final dynamic rawSettings = _eventSettingsBox.get(event.id);
          final Map<String, dynamic>? settings = rawSettings is Map
              ? Map<String, dynamic>.from(rawSettings as Map)
              : null;
          if (settings?['isDeleted'] == true) {
            continue;
          }
        }
        events.add(event);
      }
      return events;
    } catch (e, stackTrace) {
      // Handle LateInitializationError
      if (e.toString().contains('LateInitializationError')) {
        LoggerUtils.debug(
            'EventServices not initialized yet, returning empty list');
        return [];
      }
      LoggerUtils.error('Error getting all events from Hive', e, stackTrace);
      return [];
    }
  }

  List<Event> getAllUserEvents() {
    try {
      if (!_eventBox.isOpen) {
        LoggerUtils.warning('Event box is not open, cannot get user events.');
        return [];
      }
      return _eventBox.values
          .where((event) => event.eventType != EventTypeEnum.system_event.value)
          .toList();
    } catch (e, stackTrace) {
      LoggerUtils.error('Error getting all user events', e, stackTrace);
      return [];
    }
  }

  Event? getEventById(String id) {
    try {
      if (!_eventBox.isOpen) {
        LoggerUtils.warning('Event box is not open, cannot get event by ID.');
        return null;
      }
      if (!Hive.isBoxOpen(_eventSettingsBoxName)) {
        LoggerUtils.debug('Event settings box not initialized yet, returning event without user settings');
        final Event? event = _eventBox.get(id);
        return event;
      }

      final Event? event = _eventBox.get(id);
      if (event == null) return null;

      // Nếu là system event, merge với user settings
      if (event.eventType == EventTypeEnum.system_event.value) {
        final dynamic rawSettings = _eventSettingsBox.get(id);
        final Map<String, dynamic> userSettings = rawSettings is Map
            ? Map<String, dynamic>.from(rawSettings as Map)
            : <String, dynamic>{};

        if (userSettings['isDeleted'] == true) {
          return null;
        }

        if (userSettings.isNotEmpty) {
          final bool userNotifySetting =
              userSettings['isNotify'] ?? event.isNotify;
          final SimpleNotificationConfig? userNotificationConfig =
              userSettings['simpleNotificationConfig'] != null
                  ? SimpleNotificationConfig.fromJson(Map<String, dynamic>.from(
                      userSettings['simpleNotificationConfig']), isFromAPI: false)
                  : event.simpleNotificationConfig;

          final List<CustomReminderConfig>? userCustomReminders =
              userSettings['customReminders'] != null
                  ? (userSettings['customReminders'] as List)
                      .map((item) => CustomReminderConfig.fromJson(
                          Map<String, dynamic>.from(item)))
                      .toList()
                  : event.customReminders;

          return event.copyWith(
            isNotify: userNotifySetting,
            simpleNotificationConfig: userNotificationConfig,
            customReminders: userCustomReminders,
          );
        }
      }

      return event;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error getting event by ID $id', e, stackTrace);
      return null;
    }
  }

  Future<bool> hasEventOnDay(DateTime date) async {
    final monthKey = _formatMonthKey(date);
    final dateKey = date.day.toString().padLeft(2, '0');

    try {
      if (_monthlyEventCacheBox.containsKey(monthKey)) {
        final cachedMonthData = _monthlyEventCacheBox.get(monthKey);
        if (cachedMonthData != null) {
          try {
            final Map<String, dynamic> monthCache = jsonDecode(cachedMonthData);
            final hasUser =
                (monthCache['user'] as List?)?.contains(dateKey) ?? false;
            final hasSystem =
                (monthCache['system'] as List?)?.contains(dateKey) ?? false;
            final hasRecurring =
                (monthCache['recurring'] as List?)?.contains(dateKey) ?? false;
            return hasUser || hasSystem || hasRecurring;
          } catch (e) {
            LoggerUtils.error('Error decoding cache for $monthKey', e);
            await _monthlyEventCacheBox.delete(monthKey);
          }
        }
      }
      final hasEvent = await _checkEventsForDayAndCacheIfNeeded(date);
      return hasEvent;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error in hasEventOnDay for $date', e, stackTrace);
      return false;
    }
  }

  Future<bool> _checkEventsForDayAndCacheIfNeeded(DateTime date) async {
    final monthKey = _formatMonthKey(date);
    final dateKey = date.day.toString().padLeft(2, '0');
    if (_isCalculatingMonth[monthKey] ?? false) return false;
    _isCalculatingMonth[monthKey] = true;

    try {
      final allEvents = getAllEvents();
      bool eventFoundOnDate = false;
      final Map<String, List<String>> monthResult = await Isolate.run(
          () => _isolateCalculateMonthEvents(date.year, date.month, allEvents));
      await _monthlyEventCacheBox.put(monthKey, jsonEncode(monthResult));
      LoggerUtils.debug(
          'Successfully cached events for $monthKey after checking $dateKey.');
      final hasUser = monthResult['user']?.contains(dateKey) ?? false;
      final hasSystem = monthResult['system']?.contains(dateKey) ?? false;
      final hasRecurring = monthResult['recurring']?.contains(dateKey) ?? false;
      eventFoundOnDate = hasUser || hasSystem || hasRecurring;
      _notifyListeners();
      return eventFoundOnDate;
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Error in _checkEventsForDayAndCacheIfNeeded for $monthKey',
          e,
          stackTrace);
      return false;
    } finally {
      _isCalculatingMonth.remove(monthKey);
    }
  }

  List<Event> getAllEventsForDay(DateTime date) {
    try {
      final targetDate = DateTime(date.year, date.month, date.day);
      final List<Event> results = [];
      final allEvents = _eventBox.values;

      // Debug log for leap month dates
      final lunarDate = LunarService.getSolarToLunar(targetDate);
      if (lunarDate.isLeapMonth) {
        LoggerUtils.debug(
            '🌙 getAllEventsForDay called for LEAP MONTH date: ${targetDate.toString().split(' ')[0]}');
      }

      for (final event in allEvents) {
        if (staticDoesEventOccurOnDate(event, targetDate)) {
          if (event.repeatType != 'Không lặp lại' &&
              event.repeatType.isNotEmpty &&
              !event.isOccurrence) {
            results.add(_createAdjustedRecurringEvent(event, targetDate));
          } else {
            results.add(event);
          }
        }
      }
      return results;
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Error getting all events for day $date', e, stackTrace);
      return [];
    }
  }

  List<Event> getUserEventsForDay(DateTime date) {
    return getAllEventsForDay(date)
        .where((event) => event.eventType != EventTypeEnum.system_event.value)
        .toList();
  }

  List<Event> getSystemEventsForDay(DateTime date) {
    return getAllEventsForDay(date)
        .where((event) => event.eventType == EventTypeEnum.system_event.value)
        .toList();
  }

  List<Event> getEventsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? eventType,
    String? categoryId,
    bool? showOnCalendar,
  }) {
    try {
      final List<Event> results = [];
      final Set<String> addedOccurrenceIds = {};
      final normalizedStart =
          DateTime(startDate.year, startDate.month, startDate.day);
      final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
      final allEvents = _eventBox.values;

      for (final event in allEvents) {
        if (eventType != null && event.eventType != eventType) continue;
        if (categoryId != null && event.categoryId != categoryId) continue;
        if (showOnCalendar != null && event.showOnCalendar != showOnCalendar)
          continue;

        if (event.repeatType == 'Không lặp lại' ||
            event.repeatType.isEmpty ||
            event.repeatType == 'none') {
          final eventDate = DateTime(
              event.eventDate.year, event.eventDate.month, event.eventDate.day);
          if (!eventDate.isBefore(normalizedStart) &&
              !eventDate.isAfter(normalizedEnd)) {
            results.add(event);
          }
        } else {
          for (var day = normalizedStart;
              !day.isAfter(normalizedEnd);
              day = day.add(const Duration(days: 1))) {
            if (staticDoesEventOccurOnDate(event, day)) {
              final occurrenceId = '${event.id}_${_formatDateKey(day)}';
              if (!addedOccurrenceIds.contains(occurrenceId)) {
                results.add(_createAdjustedRecurringEvent(event, day));
                addedOccurrenceIds.add(occurrenceId);
              }
            }
          }
        }
      }
      results.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      return results;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error getting events by date range', e, stackTrace);
      return [];
    }
  }

  static bool staticDoesEventOccurOnDate(Event event, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);

    // Nếu là sự kiện âm lịch
    if (event.isLunar && event.originalLunarDate != null) {
      // Chuyển đổi ngày target (dương lịch) sang âm lịch - SỬ DỤNG LunarService
      final targetLunarDateTime = LunarService.getSolarToLunar(targetDate);
      final eventLunarDate = event.originalLunarDate!;

      // Chuyển đổi ngày event gốc sang âm lịch để lấy thông tin leap
      final eventSolarDate = LunarUtils.convertLunarToSolar(eventLunarDate);
      final eventLunarDateTime = LunarService.getSolarToLunar(eventSolarDate);

      // Debug print - có thể bỏ comment khi cần debug
      // if (targetLunarDateTime.isLeapMonth && targetLunarDateTime.month == 6) {
      //   print('🔍 Checking event for tháng 6 nhuận: ${event.title}');
      //   print('   Target: ${targetLunarDateTime.day}/${targetLunarDateTime.month}/${targetLunarDateTime.year} (leap: ${targetLunarDateTime.isLeapMonth})');
      //   print('   Event: ${eventLunarDateTime.day}/${eventLunarDateTime.month}/${eventLunarDateTime.year} (leap: ${eventLunarDateTime.isLeapMonth})');
      // }

      if (event.repeatType == 'Không lặp lại' ||
          event.repeatType.isEmpty ||
          event.repeatType == 'none') {
        // Kiểm tra nếu trùng ngày âm lịch chính xác + LEAP STATUS
        return targetLunarDateTime.day == eventLunarDateTime.day &&
            targetLunarDateTime.month == eventLunarDateTime.month &&
            targetLunarDateTime.year == eventLunarDateTime.year &&
            targetLunarDateTime.isLeapMonth == eventLunarDateTime.isLeapMonth;
      }

      // Kiểm tra theo kiểu lặp lại cho âm lịch
      switch (event.repeatType) {
        case 'daily':
        case 'Hằng ngày':
          return true;
        case 'weekly':
        case 'Hằng tuần':
          // Với âm lịch tuần, dựa vào thứ trong tuần của ngày dương lịch
          DateTime originalSolarDate =
              LunarUtils.convertLunarToSolar(eventLunarDate);
          return targetDate.weekday == originalSolarDate.weekday;
        case 'monthly':
        case 'Hằng tháng':
          // Lặp hàng tháng - kiểm tra trùng ngày âm lịch + LEAP STATUS
          return targetLunarDateTime.day == eventLunarDateTime.day &&
              targetLunarDateTime.isLeapMonth == eventLunarDateTime.isLeapMonth;
        case 'yearly':
        case 'Hằng năm':
          // Lặp hàng năm - kiểm tra trùng ngày/tháng âm lịch
          // LOGIC MỚI: Events hiển thị ở cả tháng thường và nhuận của cùng tháng
          bool dayMatch = targetLunarDateTime.day == eventLunarDateTime.day;
          bool monthMatch =
              targetLunarDateTime.month == eventLunarDateTime.month;

          if (!dayMatch || !monthMatch) return false;

          // Nếu event gốc là tháng thường, cho phép hiển thị ở cả thường và nhuận của cùng tháng
          if (!eventLunarDateTime.isLeapMonth) {
            return true; // Event tháng thường hiển thị ở cả thường và nhuận
          } else {
            // Event tháng nhuận chỉ hiển thị trong tháng nhuận
            return targetLunarDateTime.isLeapMonth;
          }
        default:
          return false;
      }
    } else {
      // Mã hiện tại của bạn cho sự kiện dương lịch
      final eventStartDate = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);

      if (event.repeatType == 'Không lặp lại' ||
          event.repeatType.isEmpty ||
          event.repeatType == 'none') {
        return targetDate.isAtSameMomentAs(eventStartDate);
      }
      if (targetDate.isBefore(eventStartDate)) return false;

      switch (event.repeatType) {
        case 'daily':
        case 'Hằng ngày':
          return true;
        case 'weekly':
        case 'Hằng tuần':
          return targetDate.weekday == eventStartDate.weekday;
        case 'monthly':
        case 'Hằng tháng':
          final maxDaysInTargetMonth =
              DateTime(targetDate.year, targetDate.month + 1, 0).day;
          final effectiveEventDay = eventStartDate.day <= maxDaysInTargetMonth
              ? eventStartDate.day
              : maxDaysInTargetMonth;
          return targetDate.day == effectiveEventDay;
        case 'yearly':
        case 'Hằng năm':
          if (eventStartDate.month == 2 && eventStartDate.day == 29) {
            bool isLeapTarget =
                (targetDate.year % 4 == 0 && targetDate.year % 100 != 0) ||
                    (targetDate.year % 400 == 0);
            return isLeapTarget &&
                targetDate.month == 2 &&
                targetDate.day == 29;
          }
          return targetDate.day == eventStartDate.day &&
              targetDate.month == eventStartDate.month;
        default:
          return false;
      }
    }
  }

  // --- Helpers ---
  String _formatDateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String _formatMonthKey(DateTime date) => DateFormat('yyyy-MM').format(date);
  Event _createAdjustedRecurringEvent(
      Event originalEvent, DateTime targetDate) {
    String adjustedTitle = originalEvent.title;
    String adjustedRepeatType = originalEvent.repeatType;

    // Nếu là lunar event và target date là tháng nhuận, thêm indicator
    if (originalEvent.isLunar && originalEvent.originalLunarDate != null) {
      final targetLunarDate = LunarService.getSolarToLunar(targetDate);
      final originalLunarDate =
          LunarService.getSolarToLunar(originalEvent.eventDate);

      // Debug log
      if (originalEvent.title.contains('tháng 6')) {
        LoggerUtils.debug(
            '🌙 _createAdjustedRecurringEvent: ${originalEvent.title}');
        LoggerUtils.debug(
            '   Target: ${targetDate.toString().split(' ')[0]} - Leap: ${targetLunarDate.isLeapMonth}');
        LoggerUtils.debug(
            '   Original: ${originalEvent.eventDate.toString().split(' ')[0]} - Leap: ${originalLunarDate.isLeapMonth}');
      }

      // Nếu target là tháng nhuận mà original là tháng thường
      if (targetLunarDate.isLeapMonth && !originalLunarDate.isLeapMonth) {
        // Format đẹp hơn: "Ngày Mùng Một tháng 6 Âm lịch" -> "Ngày Mùng Một tháng 6 nhuận Âm lịch"
        String newTitle = originalEvent.title;

        // Thay thế "tháng X Âm lịch" thành "tháng X nhuận Âm lịch"
        final RegExp pattern = RegExp(r'tháng (\d+) Âm lịch');
        final match = pattern.firstMatch(newTitle);

        if (match != null) {
          final monthNumber = match.group(1);
          newTitle = newTitle.replaceAll(
              'tháng $monthNumber Âm lịch', 'tháng $monthNumber nhuận Âm lịch');
        } else {
          // Fallback nếu không match pattern
          newTitle = originalEvent.title;
        }

        adjustedTitle = newTitle;
        // For leap month events, change repeat type to non-repeating
        adjustedRepeatType = 'none';
        LoggerUtils.debug(
            '   ✅ Adjusted to: $adjustedTitle with repeatType=none');
      }
    }

    return originalEvent.copyWith(
      id: '${originalEvent.id}_${_formatDateKey(targetDate)}',
      title: adjustedTitle, // Dynamic title
      repeatType: adjustedRepeatType, // Dynamic repeat type
      eventDate: DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        originalEvent.eventDate.hour,
        originalEvent.eventDate.minute,
      ),
      isOccurrence: true,
      originalEventId: originalEvent.id,
      createdAt: originalEvent.createdAt,
      updatedAt: originalEvent.updatedAt,
    );
  }

  /// Tìm kiếm sự kiện theo từ khóa (title hoặc description)
  Future<List<Event>> searchEventsByKeyword(
    String keyword, {
    List<Event>? candidateEvents,
  }) async {
    final trimmedKeyword = keyword.trim();
    if (trimmedKeyword.isEmpty) return [];

    final normalizedKeyword = VietnameseTextUtils.normalize(trimmedKeyword);
    if (normalizedKeyword.isEmpty) return [];

    final List<String> keywordWords = normalizedKeyword
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();

    final List<Event> allEvents =
        candidateEvents != null ? List<Event>.from(candidateEvents) : getAllEvents();
    if (allEvents.isEmpty) return [];

    const int maxBaseMatches = 120;
    const int maxExpandedResults = 150;

    if (candidateEvents != null) {
      final List<_ScoredMatch> localMatches = [];
      for (int index = 0; index < allEvents.length; index++) {
        final event = allEvents[index];
        final entry = _getSearchIndexEntry(event);
        if (_matchesKeywordNormalizedText(
          normalizedKeyword,
          keywordWords,
          entry.normalizedTitle,
          entry.abbreviation,
        )) {
          final score = _calculateSimilarityNormalizedText(
            normalizedKeyword,
            keywordWords,
            entry.normalizedTitle,
          );
          localMatches.add(_ScoredMatch(index, score));
        }
      }

      if (localMatches.isEmpty) {
        LoggerUtils.debug(
            'searchEventsByKeyword (local candidates): no events matched keyword "$keyword"');
        return [];
      }

      localMatches.sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.index.compareTo(b.index);
      });

      final List<Event> localResults = [];
      for (final match in localMatches.take(maxBaseMatches)) {
        localResults.add(allEvents[match.index]);
      }
      LoggerUtils.debug(
          'searchEventsByKeyword (local candidates): returning ${localResults.length} events for keyword "$keyword"');
      return localResults;
    }

    final bool shouldExpandLeap = true;

    final List<_SearchEventPayload> payloads = [];
    for (int index = 0; index < allEvents.length; index++) {
      final event = allEvents[index];
      final searchIndex = _getSearchIndexEntry(event);
      payloads.add(
        _SearchEventPayload(
          index: index,
          id: event.id,
          title: event.title,
          normalizedTitle: searchIndex.normalizedTitle,
          abbreviation: searchIndex.abbreviation,
          isLunar: event.isLunar,
          eventDate: event.eventDate,
          repeatType: event.repeatType,
          isOccurrence: event.isOccurrence,
          originalLunarDate: event.originalLunarDate,
        ),
      );
    }

    final _SearchIsolateInput input = _SearchIsolateInput(
      normalizedKeyword: normalizedKeyword,
      keywordWords: keywordWords,
      events: payloads,
      currentYear: DateTime.now().year,
      maxBaseMatches: maxBaseMatches,
      maxExpandedResults: maxExpandedResults,
      keywordLength: trimmedKeyword.replaceAll(' ', '').length,
      allowLeapExpansion: shouldExpandLeap,
    );

    final Map<String, dynamic> rawResult =
        await compute(_searchEventsInIsolate, input.toMap());
    final _SearchIsolateResult isolateResult =
        _SearchIsolateResult.fromMap(rawResult);

    if (isolateResult.matchIndices.isEmpty &&
        isolateResult.leapOccurrences.isEmpty) {
      LoggerUtils.debug(
          'searchEventsByKeyword: no events matched keyword "$keyword"');
      return [];
    }

    final List<Event> results = [];
    final int maxResults = maxExpandedResults;

    for (final index in isolateResult.matchIndices) {
      if (index >= 0 && index < allEvents.length) {
        results.add(allEvents[index]);
        if (results.length >= maxResults) break;
      }
    }

    if (results.length < maxResults) {
      for (final occurrence in isolateResult.leapOccurrences) {
        if (occurrence.baseIndex >= 0 &&
            occurrence.baseIndex < allEvents.length) {
          final baseEvent = allEvents[occurrence.baseIndex];
          final occurrenceEvent = baseEvent.copyWith(
            id: occurrence.generatedId,
            title: occurrence.adjustedTitle,
            eventDate: occurrence.occurrenceDate,
            isOccurrence: true,
            originalEventId: baseEvent.originalEventId ?? baseEvent.id,
          );
          results.add(occurrenceEvent);
          if (results.length >= maxResults) break;
        }
      }
    }

    LoggerUtils.debug(
        'Found ${isolateResult.matchIndices.length} base events, expanded to ${results.length} events (including leap month occurrences) matching "$keyword".');
    return results;
  }

  _SearchIndexEntry _getSearchIndexEntry(Event event) {
    final cacheKey = event.id;
    final int updatedAtMs = event.updatedAt.millisecondsSinceEpoch;
    final cached = _searchIndexCache[cacheKey];
    if (cached != null && cached.updatedAtMs == updatedAtMs) {
      return cached;
    }

    final normalizedTitle = VietnameseTextUtils.normalize(event.title);
    final abbreviation = _buildAbbreviationFromNormalized(normalizedTitle);

    final entry = _SearchIndexEntry(
      normalizedTitle: normalizedTitle,
      abbreviation: abbreviation,
      updatedAtMs: updatedAtMs,
    );
    _searchIndexCache[cacheKey] = entry;
    return entry;
  }

  void _notifyListeners() =>
      _eventStreamController.add(!_eventStreamController.value);
  Future<void> _clearMonthlyCacheForDate(DateTime date) async {
    final monthKey = _formatMonthKey(date);
    await _monthlyEventCacheBox.delete(monthKey);
    LoggerUtils.debug('Cleared monthly cache for $monthKey');
  }

  Future<void> _clearMonthlyCacheForMonths(Set<String> monthKeys) async {
    for (final key in monthKeys) {
      await _monthlyEventCacheBox.delete(key);
    }
    LoggerUtils.debug(
        'Cleared monthly cache for keys: ${monthKeys.join(', ')}');
  }

  Future<void> _clearAllMonthlyCache() async {
    await _monthlyEventCacheBox.clear();
    LoggerUtils.debug('Cleared all monthly event cache.');
  }

  Future<void> _clearAllRecurringCacheInMonthlyBox() async {
    final List<String> keys =
        _monthlyEventCacheBox.keys.cast<String>().toList();
    final Map<String, String> updates = {};
    final List<String> keysToDelete = [];

    for (final key in keys) {
      final cachedData = _monthlyEventCacheBox.get(key);
      if (cachedData != null) {
        try {
          final Map<String, dynamic> monthCache = jsonDecode(cachedData);
          if (monthCache.containsKey('recurring') &&
              (monthCache['recurring'] as List).isNotEmpty) {
            monthCache.remove('recurring');
            if (monthCache['user']?.isNotEmpty == true ||
                monthCache['system']?.isNotEmpty == true) {
              updates[key] = jsonEncode(monthCache);
            } else {
              keysToDelete.add(key);
            }
          }
        } catch (e) {
          LoggerUtils.error('Error processing recurring cache for key $key', e);
          keysToDelete.add(key);
        }
      }
    }
    if (updates.isNotEmpty) await _monthlyEventCacheBox.putAll(updates);
    if (keysToDelete.isNotEmpty)
      await _monthlyEventCacheBox.deleteAll(keysToDelete);
    LoggerUtils.debug('Cleared recurring event entries from monthly cache.');
  }

  Future<void> _calculateAndCacheMonthEvents(int year, int month) async {
    final monthKey = _formatMonthKey(DateTime(year, month));
    if (_isCalculatingMonth[monthKey] ?? false) return;
    _isCalculatingMonth[monthKey] = true;
    LoggerUtils.debug('Starting cache calculation for $monthKey');

    try {
      final List<Event> currentEvents =
          _eventBox.values.map((e) => e.copyWith()).toList();
      final Map<String, List<String>>? result = await Isolate.run(
          () => _isolateCalculateMonthEvents(year, month, currentEvents));
      if (result != null) {
        await _monthlyEventCacheBox.put(monthKey, jsonEncode(result));
        LoggerUtils.debug('Successfully cached events for $monthKey');
        _notifyListeners();
      } else {
        LoggerUtils.warning('Calculation returned null for $monthKey');
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Error calculating cache for $monthKey', e, stackTrace);
    } finally {
      _isCalculatingMonth.remove(monthKey);
      LoggerUtils.debug('Finished cache calculation for $monthKey');
    }
  }

  int countEventsForDay(DateTime date) => getAllEventsForDay(date).length;
  int countUserEventsForDay(DateTime date) => getUserEventsForDay(date).length;
  int countSystemEventsForDay(DateTime date) =>
      getSystemEventsForDay(date).length;
  static bool isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  bool _isSameMonth(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month;

  Future<void> _scheduleOrCancelEventNotification(Event event) async {
    try {
      if (event.isNotify) {
        LoggerUtils.debug('Scheduling notifications for event: ${event.id}');
        await _notificationService.scheduleEventNotification(event);
      } else {
        LoggerUtils.debug('Cancelling notifications for event: ${event.id}');
        await _cancelEventNotification(event.id);
      }
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Error scheduling/cancelling notification for event ${event.id}',
          e,
          stackTrace);
    }
  }

  // Performance control: Rate limiting for bulk operations
  static const int _maxConcurrentNotifications = 5;
  static const Duration _notificationBatchDelay = Duration(milliseconds: 100);

  Future<void> _scheduleOrCancelEventNotificationWithRateLimit(
      Event event) async {
    try {
      if (event.isNotify) {
        LoggerUtils.debug('Scheduling notifications for event: ${event.id}');
        await _notificationService.scheduleEventNotification(event);
      } else {
        LoggerUtils.debug('Cancelling notifications for event: ${event.id}');
        await _cancelEventNotification(event.id);
      }

      // Add small delay to prevent system overload
      await Future.delayed(_notificationBatchDelay);
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Error scheduling/cancelling notification for event ${event.id}',
          e,
          stackTrace);
    }
  }

  // Bulk operations with performance control
  Future<void> enableNotificationsForSystemEvents() async {
    LoggerUtils.info('Enabling notifications for system events...');
    final systemEvents =
        _eventBox.values.where((e) => e.eventType == 'system').toList();

    int processedCount = 0;
    final List<Future<void>> futures = [];

    for (final event in systemEvents) {
      if (event.isNotify && event.simpleNotificationConfig == null) {
        LoggerUtils.debug(
            'Enabling notifications for system event: ${event.id}');

        futures.add(_scheduleOrCancelEventNotificationWithRateLimit(event));
        processedCount++;

        // Process in batches to prevent system overload
        if (futures.length >= _maxConcurrentNotifications) {
          await Future.wait(futures);
          futures.clear();
          LoggerUtils.debug(
              'Processed batch of $_maxConcurrentNotifications notifications');
        }
      }
    }

    // Process remaining notifications
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    LoggerUtils.info('Enabled notifications for $processedCount system events');
  }

  Future<void> disableNotificationsForSystemEvents() async {
    LoggerUtils.info('Disabling notifications for system events...');
    final systemEvents =
        _eventBox.values.where((e) => e.eventType == 'system').toList();

    int processedCount = 0;
    final List<Future<void>> futures = [];

    for (final event in systemEvents) {
      if (event.isNotify) {
        LoggerUtils.debug(
            'Disabling notifications for system event: ${event.id}');

        // Cancel notification
        futures.add(_cancelEventNotification(event.id));
        processedCount++;

        // Process in batches
        if (futures.length >= _maxConcurrentNotifications) {
          await Future.wait(futures);
          futures.clear();
          LoggerUtils.debug(
              'Processed batch of $_maxConcurrentNotifications cancellations');
        }
      }
    }

    // Process remaining cancellations
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    LoggerUtils.info(
        'Disabled notifications for $processedCount system events');
  }

  Future<void> _cancelEventNotification(String eventId) async {
    try {
      LoggerUtils.debug('Cancelling notifications for event ID: $eventId');
      await _notificationService.cancelEventNotification(eventId);
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Error cancelling notification for event ID $eventId', e, stackTrace);
    }
  }
} // Kết thúc class EventServices

Map<String, List<String>> _isolateCalculateMonthEvents(
    int year, int month, List<Event> allEvents) {
  final Map<String, Set<String>> daysWithEvents = {
    'user': <String>{},
    'system': <String>{},
    'recurring': <String>{}
  };
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0);

  for (final event in allEvents) {
    // Sửa điều kiện kiểm tra repeatType
    if (event.repeatType == 'Không lặp lại' ||
        event.repeatType.isEmpty ||
        event.repeatType == 'none') {
      final eventDate = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);
      if (eventDate.year == year && eventDate.month == month) {
        final dateKey = eventDate.day.toString().padLeft(2, '0');
        if (event.eventType == EventTypeEnum.user_event.value) {
          daysWithEvents['user']!.add(dateKey);
        } else {
          daysWithEvents['system']!.add(dateKey);
        }
      }
    } else {
      for (var day = startDate;
          !day.isAfter(endDate);
          day = day.add(const Duration(days: 1))) {
        if (EventServices.staticDoesEventOccurOnDate(event, day)) {
          final dateKey = day.day.toString().padLeft(2, '0');
          daysWithEvents['recurring']!.add(dateKey);
        }
      }
    }
  }
  return {
    'user': daysWithEvents['user']!.toList(),
    'system': daysWithEvents['system']!.toList(),
    'recurring': daysWithEvents['recurring']!.toList()
  };
}

/// Helper class for priority queue in iOS notification scheduling
class _EventWithPriority {
  final Event event;
  final int priority;
  final DateTime nextOccurrence;
  
  _EventWithPriority(this.event, this.priority, this.nextOccurrence);
}

class _SearchIsolateInput {
  final String normalizedKeyword;
  final List<String> keywordWords;
  final List<_SearchEventPayload> events;
  final int currentYear;
  final int maxBaseMatches;
  final int maxExpandedResults;
  final int keywordLength;
  final bool allowLeapExpansion;

  const _SearchIsolateInput({
    required this.normalizedKeyword,
    required this.keywordWords,
    required this.events,
    required this.currentYear,
    required this.maxBaseMatches,
    required this.maxExpandedResults,
    required this.keywordLength,
    required this.allowLeapExpansion,
  });

  Map<String, dynamic> toMap() => {
        'normalizedKeyword': normalizedKeyword,
        'keywordWords': keywordWords,
        'events': events.map((e) => e.toMap()).toList(),
        'currentYear': currentYear,
        'maxBaseMatches': maxBaseMatches,
        'maxExpandedResults': maxExpandedResults,
        'keywordLength': keywordLength,
        'allowLeapExpansion': allowLeapExpansion,
      };

  static _SearchIsolateInput fromMap(Map<String, dynamic> map) {
    return _SearchIsolateInput(
      normalizedKeyword: map['normalizedKeyword'] as String,
      keywordWords:
          (map['keywordWords'] as List<dynamic>).cast<String>().toList(),
      events: (map['events'] as List<dynamic>)
          .map((e) =>
              _SearchEventPayload.fromMap((e as Map<dynamic, dynamic>).cast<String, dynamic>()))
          .toList(),
      currentYear: map['currentYear'] as int,
      maxBaseMatches: map['maxBaseMatches'] as int,
      maxExpandedResults: map['maxExpandedResults'] as int,
      keywordLength: map['keywordLength'] as int,
      allowLeapExpansion: map['allowLeapExpansion'] as bool,
    );
  }
}

class _SearchEventPayload {
  final int index;
  final String id;
  final String title;
  final String normalizedTitle;
  final String abbreviation;
  final bool isLunar;
  final DateTime eventDate;
  final String repeatType;
  final bool isOccurrence;
  final DateTime? originalLunarDate;

  const _SearchEventPayload({
    required this.index,
    required this.id,
    required this.title,
    required this.normalizedTitle,
    required this.abbreviation,
    required this.isLunar,
    required this.eventDate,
    required this.repeatType,
    required this.isOccurrence,
    required this.originalLunarDate,
  });

  Map<String, dynamic> toMap() => {
        'index': index,
        'id': id,
        'title': title,
        'normalizedTitle': normalizedTitle,
        'abbreviation': abbreviation,
        'isLunar': isLunar,
        'eventDateMs': eventDate.millisecondsSinceEpoch,
        'repeatType': repeatType,
        'isOccurrence': isOccurrence,
        'originalLunarDateMs': originalLunarDate?.millisecondsSinceEpoch,
      };

  static _SearchEventPayload fromMap(Map<String, dynamic> map) {
    return _SearchEventPayload(
      index: map['index'] as int,
      id: map['id'] as String,
      title: map['title'] as String,
      normalizedTitle: map['normalizedTitle'] as String,
      abbreviation: map['abbreviation'] as String,
      isLunar: map['isLunar'] as bool,
      eventDate:
          DateTime.fromMillisecondsSinceEpoch(map['eventDateMs'] as int),
      repeatType: map['repeatType'] as String,
      isOccurrence: map['isOccurrence'] as bool,
      originalLunarDate: map['originalLunarDateMs'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['originalLunarDateMs'] as int)
          : null,
    );
  }
}

class _SearchIsolateResult {
  final List<int> matchIndices;
  final List<_LeapOccurrenceData> leapOccurrences;

  const _SearchIsolateResult(this.matchIndices, this.leapOccurrences);

  Map<String, dynamic> toMap() => {
        'matchIndices': matchIndices,
        'leapOccurrences':
            leapOccurrences.map((e) => e.toMap()).toList(),
      };

  static _SearchIsolateResult fromMap(Map<String, dynamic> map) {
    return _SearchIsolateResult(
      (map['matchIndices'] as List<dynamic>).cast<int>().toList(),
      (map['leapOccurrences'] as List<dynamic>)
          .map((e) => _LeapOccurrenceData.fromMap(
              (e as Map<dynamic, dynamic>).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class _LeapOccurrenceData {
  final int baseIndex;
  final DateTime occurrenceDate;
  final String generatedId;
  final String adjustedTitle;

  const _LeapOccurrenceData({
    required this.baseIndex,
    required this.occurrenceDate,
    required this.generatedId,
    required this.adjustedTitle,
  });

  Map<String, dynamic> toMap() => {
        'baseIndex': baseIndex,
        'occurrenceDateMs': occurrenceDate.millisecondsSinceEpoch,
        'generatedId': generatedId,
        'adjustedTitle': adjustedTitle,
      };

  static _LeapOccurrenceData fromMap(Map<String, dynamic> map) {
    return _LeapOccurrenceData(
      baseIndex: map['baseIndex'] as int,
      occurrenceDate: DateTime.fromMillisecondsSinceEpoch(
          map['occurrenceDateMs'] as int),
      generatedId: map['generatedId'] as String,
      adjustedTitle: map['adjustedTitle'] as String,
    );
  }
}

class _ScoredMatch {
  final int index;
  final double score;

  const _ScoredMatch(this.index, this.score);
}

String _buildAbbreviationFromNormalized(String normalizedTitle) {
  if (normalizedTitle.isEmpty) return '';
  final buffer = StringBuffer();
  for (final word in normalizedTitle.split(' ')) {
    if (word.isEmpty) continue;
    buffer.write(word[0]);
  }
  return buffer.toString();
}

bool _matchesKeywordNormalizedText(
  String normalizedKeyword,
  List<String> keywordWords,
  String normalizedTitle,
  String abbreviation,
) {
  if (normalizedTitle.contains(normalizedKeyword)) {
    return true;
  }

  if (keywordWords.isEmpty) return false;

  int matchedWords = 0;
  for (final word in keywordWords) {
    if (word.isEmpty) continue;
    if (normalizedTitle.contains(word)) {
      matchedWords++;
    }
  }

  if (matchedWords >= (keywordWords.length * 0.5)) {
    return true;
  }

  return abbreviation.isNotEmpty &&
      abbreviation.contains(normalizedKeyword);
}

double _calculateSimilarityNormalizedText(
  String normalizedKeyword,
  List<String> keywordWords,
  String normalizedTitle,
) {
  if (normalizedTitle == normalizedKeyword) {
    return 1.0;
  }
  if (normalizedTitle.contains(normalizedKeyword)) {
    return 0.8;
  }
  if (keywordWords.isEmpty) {
    return 0.0;
  }

  int matchedWords = 0;
  for (final word in keywordWords) {
    if (word.isEmpty) continue;
    if (normalizedTitle.contains(word)) {
      matchedWords++;
    }
  }

  return matchedWords / keywordWords.length;
}

DateTime? _findSolarDateForLunarLeapMonth(
  int lunarDay,
  int lunarMonth,
  int year,
  bool isLeap, {
  bool enableLogging = true,
}) {
  try {
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final testSolarDate = DateTime(year, month, day);
        final lunarInfo = LunarService.getSolarToLunar(testSolarDate);

        if (lunarInfo.day == lunarDay &&
            lunarInfo.month == lunarMonth &&
            lunarInfo.isLeapMonth == isLeap) {
          if (enableLogging) {
            LoggerUtils.debug(
                '🌙 Found solar date ${testSolarDate.toString().split(' ')[0]} for lunar $lunarDay/$lunarMonth/$year (leap: $isLeap)');
          }
          return testSolarDate;
        }
      }
    }

    if (enableLogging) {
      LoggerUtils.warning(
          '🌙 Could not find solar date for lunar $lunarDay/$lunarMonth/$year (leap: $isLeap)');
    }
    return null;
  } catch (e) {
    if (enableLogging) {
      LoggerUtils.error('Error finding solar date for lunar date', e);
    }
    return null;
  }
}

String _adjustTitleForLeapMonth(String originalTitle, int lunarMonth) {
  final RegExp pattern = RegExp(r'tháng (\d+) Âm lịch');
  final match = pattern.firstMatch(originalTitle);

  if (match != null) {
    final monthNumber = match.group(1);
    return originalTitle.replaceAll(
        'tháng $monthNumber Âm lịch', 'tháng $monthNumber nhuận Âm lịch');
  }
  return originalTitle;
}

Map<String, dynamic> _searchEventsInIsolate(Map<String, dynamic> rawInput) {
  final _SearchIsolateInput input =
      _SearchIsolateInput.fromMap(rawInput);
  final List<_ScoredMatch> scoredMatches = [];
  for (final payload in input.events) {
    if (_matchesKeywordNormalizedText(
      input.normalizedKeyword,
      input.keywordWords,
      payload.normalizedTitle,
      payload.abbreviation,
    )) {
      final score = _calculateSimilarityNormalizedText(
        input.normalizedKeyword,
        input.keywordWords,
        payload.normalizedTitle,
      );
      scoredMatches.add(_ScoredMatch(payload.index, score));
    }
  }

  if (scoredMatches.isEmpty) {
    return const _SearchIsolateResult([], []).toMap();
  }

  scoredMatches.sort((a, b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return a.index.compareTo(b.index);
  });

  final List<_ScoredMatch> limitedMatches =
      scoredMatches.take(input.maxBaseMatches).toList();
  final List<int> orderedIndices =
      limitedMatches.map((match) => match.index).toList();

  final bool allowLeapExpansion =
      input.allowLeapExpansion &&
      orderedIndices.length <= 60 &&
      input.keywordLength >= 3;

  var leapOccurrences = <_LeapOccurrenceData>[];
  if (allowLeapExpansion) {
    final int currentYear = input.currentYear;
    final List<int> candidateYears = [
      currentYear - 1,
      currentYear,
      currentYear + 1
    ];

    for (final match in limitedMatches) {
      final payload = input.events[match.index];
      if (!payload.isLunar ||
          payload.originalLunarDate == null ||
          payload.isOccurrence ||
          (payload.repeatType != 'yearly' && payload.repeatType != 'Hằng năm')) {
        continue;
      }

      for (final year in candidateYears) {
        for (int month = 1; month <= 12; month++) {
          final testDate = DateTime(year, month, 15);
          final lunarInfo = LunarService.getSolarToLunar(testDate);
          if (lunarInfo.isLeapMonth &&
              lunarInfo.month == payload.originalLunarDate!.month) {
            final leapMonthDate = _findSolarDateForLunarLeapMonth(
              payload.originalLunarDate!.day,
              payload.originalLunarDate!.month,
              year,
              true,
              enableLogging: false,
            );

            if (leapMonthDate != null) {
              final adjustedTitle = _adjustTitleForLeapMonth(
                payload.title,
                payload.originalLunarDate!.month,
              );
              final generatedId =
                  '${payload.id}_leap_${year}_${month}_${leapMonthDate.day}';
              leapOccurrences.add(
                _LeapOccurrenceData(
                  baseIndex: match.index,
                  occurrenceDate: leapMonthDate,
                  generatedId: generatedId,
                  adjustedTitle: adjustedTitle,
                ),
              );
            }
            break;
          }
        }
      }
    }

    final int availableSlots =
        input.maxExpandedResults - orderedIndices.length;
    if (availableSlots < leapOccurrences.length) {
      final int takeCount =
          availableSlots > 0 ? availableSlots : 0;
      leapOccurrences = leapOccurrences.take(takeCount).toList();
    }
  }

  return _SearchIsolateResult(orderedIndices, leapOccurrences).toMap();
}
// END REPLACE app/services/event_services.dart
