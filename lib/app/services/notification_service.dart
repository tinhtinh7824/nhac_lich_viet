import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../data/models/event_model.dart';
import '../data/models/custom_reminder_config.dart';
import '../utils/logger_utils.dart';

/// Smart Notification Service with intelligent scheduling for Vietnamese Calendar Events
///
/// Features:
/// - System events: Notified at 7:00 AM on the event day
/// - User events: Notified based on user preferences (simple config or custom reminders)
/// - Supports both simple notification config and custom reminders
/// - Real notification scheduling with flutter_local_notifications
class NotificationService extends GetxService {
  static const String _channelId = 'event_notifications';
  static const String _channelName = 'Event Notifications';
  static const String _channelDescription = 'Notifications for upcoming events';

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  bool _canScheduleExactNotifications = false;
  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _createNotificationChannel();
      }

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      LoggerUtils.debug('NotificationService initialized successfully with real notifications');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to initialize NotificationService', e, stackTrace);
      _isInitialized = false;
    }
  }

  Future<void> _createNotificationChannel() async {
    const androidNotificationChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
      final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
      _canScheduleExactNotifications = canScheduleExact ?? false;
    }
  }

  Future<bool> _isExactAlarmAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    if (_canScheduleExactNotifications) {
      return true;
    }

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? canScheduleExact = await androidImplementation?.canScheduleExactNotifications();
    _canScheduleExactNotifications = canScheduleExact ?? false;
    return _canScheduleExactNotifications;
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      LoggerUtils.debug('Notification tapped with payload: $payload');
      // Handle notification tap - navigate to event detail if needed
    }
  }

  /// Schedule notification for an event
  Future<void> scheduleEventNotification(Event event) async {
    try {
      if (!_isInitialized) {
        LoggerUtils.warning('NotificationService not initialized, skipping notification for event: ${event.id}');
        return;
      }

      LoggerUtils.debug('Scheduling notification for event: ${event.id}');

      // Skip if notifications are disabled for this event
      if (!event.isNotify) {
        LoggerUtils.debug('Notifications disabled for event: ${event.id}');
        return;
      }

      // Logic for different event types
      if (event.eventType == 'system_event') {
        await _scheduleSystemEventNotification(event);
      } else if (event.eventType == 'user_event') {
        await _scheduleUserEventNotification(event);
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to schedule notification for event ${event.id}', e, stackTrace);
    }
  }

  /// Schedule notification for system events at 7:00 AM on the event day
  Future<void> _scheduleSystemEventNotification(Event event) async {
    try {
      // System events are always notified at 7:00 AM on the event day
      final eventDate = event.eventDate;
      final notificationTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        7, // 7:00 AM
        0, // 0 minutes
      );

      // Only schedule if the notification time is in the future
      if (notificationTime.isAfter(DateTime.now())) {
        await _scheduleNotificationAt(
          notificationTime,
          event.id,
          'Sự kiện hôm nay',
          '${event.title} - ${event.description}',
          event.id,
        );

        LoggerUtils.debug(
          'Scheduled system event notification for ${event.title} at 7:00 AM on ${eventDate.toIso8601String()}',
        );
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to schedule system event notification', e, stackTrace);
    }
  }

  /// Schedule notification for user events based on their preferences
  Future<void> _scheduleUserEventNotification(Event event) async {
    try {
      final eventDateTime = _combineEventDateTime(event);

      // Handle simple notification config
      if (event.simpleNotificationConfig != null) {
        await _handleSimpleNotificationConfig(event, eventDateTime);
      }

      // Handle custom reminders
      if (event.customReminders != null && event.customReminders!.isNotEmpty) {
        await _handleCustomReminders(event, eventDateTime);
      }

      // If no notification config is set, use default (notify on event day at user's preferred time)
      if (event.simpleNotificationConfig == null &&
          (event.customReminders == null || event.customReminders!.isEmpty)) {
        await _scheduleDefaultUserNotification(event, eventDateTime);
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to schedule user event notification', e, stackTrace);
    }
  }

  /// Handle simple notification configuration
  Future<void> _handleSimpleNotificationConfig(Event event, DateTime eventDateTime) async {
    final config = event.simpleNotificationConfig!;

    // Parse notification time
    final timeParts = config.notifyTime.split(':');
    final notifyHour = int.tryParse(timeParts[0]) ?? 7;
    final notifyMinute = int.tryParse(timeParts[1]) ?? 0;

    // Schedule notification on the event day
    if (config.notifyOnDay) {
      final notificationTime = DateTime(
        event.eventDate.year,
        event.eventDate.month,
        event.eventDate.day,
        notifyHour,
        notifyMinute,
      );

      if (notificationTime.isAfter(DateTime.now())) {
        await _scheduleNotificationAt(
          notificationTime,
          '${event.id}_on_day',
          'Sự kiện hôm nay',
          '${event.title} - ${event.description}',
          event.id,
        );
      }
    }

    // Schedule notifications for days before
    for (final minutesBefore in config.notifyDaysBefore) {
      final notificationTime = eventDateTime.subtract(Duration(minutes: minutesBefore));

      if (notificationTime.isAfter(DateTime.now())) {
        final daysBefore = (minutesBefore / 1440).round(); // Convert minutes to days
        final title = daysBefore > 0
            ? 'Sự kiện sắp tới ($daysBefore ngày nữa)'
            : 'Sự kiện sắp tới';

        await _scheduleNotificationAt(
          notificationTime,
          '${event.id}_${minutesBefore}_before',
          title,
          '${event.title} - ${event.description}',
          event.id,
        );
      }
    }
  }

  /// Handle custom reminders
  Future<void> _handleCustomReminders(Event event, DateTime eventDateTime) async {
    for (final reminder in event.customReminders!) {
      DateTime? notificationTime;

      if (reminder.type == CustomReminderType.countdown) {
        final hours = reminder.countdownHours ?? 0;
        final minutes = reminder.countdownMinutes ?? 0;
        notificationTime = eventDateTime.subtract(
          Duration(hours: hours, minutes: minutes),
        );
      } else if (reminder.type == CustomReminderType.specificDate &&
                 reminder.specificDateTime != null) {
        notificationTime = reminder.specificDateTime!;
      }

      if (notificationTime != null && notificationTime.isAfter(DateTime.now())) {
        await _scheduleNotificationAt(
          notificationTime,
          '${event.id}_custom_${reminder.id}',
          'Nhắc nhở sự kiện',
          '${event.title} - ${event.description}',
          event.id,
        );
      }
    }
  }

  /// Schedule default notification for user events without specific config
  Future<void> _scheduleDefaultUserNotification(Event event, DateTime eventDateTime) async {
    // Default: notify 1 day before at 7:00 AM
    final defaultNotificationTime = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day - 1, // 1 day before
      7, // 7:00 AM
      0, // 0 minutes
    );

    if (defaultNotificationTime.isAfter(DateTime.now())) {
      await _scheduleNotificationAt(
        defaultNotificationTime,
        '${event.id}_default',
        'Sự kiện sắp tới (ngày mai)',
        '${event.title} - ${event.description}',
        event.id,
      );
    }
  }

  /// Combine event date and time into a single DateTime
  DateTime _combineEventDateTime(Event event) {
    final timeParts = event.eventTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;

    return DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
      hour,
      minute,
    );
  }

  /// Schedule a notification at a specific time (real implementation)
  Future<void> _scheduleNotificationAt(
    DateTime scheduledTime,
    String notificationId,
    String title,
    String body,
    String eventId,
  ) async {
    if (!_isInitialized) {
      LoggerUtils.warning('NotificationService not initialized, cannot schedule notification');
      return;
    }

    try {
      // Convert to timezone aware datetime
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

      // Create unique notification ID from notificationId hash
      final int uniqueId = notificationId.hashCode.abs();

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final bool canUseExactAlarm = await _isExactAlarmAvailable();
      final AndroidScheduleMode scheduleMode = canUseExactAlarm
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      if (!canUseExactAlarm) {
        LoggerUtils.warning(
          'Exact alarm permission not granted. Falling back to inexact scheduling for $eventId',
        );
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        uniqueId,
        title,
        body,
        scheduledDate,
        notificationDetails,
        payload: eventId,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      LoggerUtils.debug(
        '✅ Real notification scheduled: $title at ${scheduledTime.toIso8601String()} for event $eventId (ID: $uniqueId)',
      );
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to schedule real notification', e, stackTrace);
    }
  }

  /// Cancel notification for an event
  Future<void> cancelEventNotification(String eventId) async {
    if (!_isInitialized) {
      LoggerUtils.warning('NotificationService not initialized, cannot cancel notifications');
      return;
    }

    try {
      // Get all pending notifications
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

      // Cancel notifications related to this event
      int cancelledCount = 0;
      for (final notification in pendingNotifications) {
        if (notification.payload == eventId) {
          await _flutterLocalNotificationsPlugin.cancel(notification.id);
          cancelledCount++;
        }
      }

      LoggerUtils.debug('✅ Cancelled $cancelledCount notifications for event: $eventId');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to cancel notification for event $eventId', e, stackTrace);
    }
  }

  /// Get pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests() async {
    if (!_isInitialized) {
      LoggerUtils.warning('NotificationService not initialized, cannot get pending notifications');
      return [];
    }

    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      LoggerUtils.debug('✅ Retrieved ${pendingNotifications.length} pending notifications');
      return pendingNotifications;
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to get pending notifications', e, stackTrace);
      return [];
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      LoggerUtils.warning('NotificationService not initialized, cannot cancel all notifications');
      return;
    }

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      LoggerUtils.debug('✅ Cancelled all notifications');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to cancel all notifications', e, stackTrace);
    }
  }

  /// Test function to validate notification logic and actually schedule notifications (for debugging)
  Future<String> testNotificationLogic(Event event) async {
    try {
      final now = DateTime.now();
      List<String> scheduledNotifications = [];

      if (!event.isNotify) {
        return 'Thông báo đã bị tắt cho sự kiện này';
      }

      // Actually schedule the real notifications for testing
      await scheduleEventNotification(event);

      if (event.eventType == 'system_event') {
        final notificationTime = DateTime(
          event.eventDate.year,
          event.eventDate.month,
          event.eventDate.day,
          7, 0,
        );

        if (notificationTime.isAfter(now)) {
          scheduledNotifications.add(
            'Sự kiện hệ thống: Thông báo lúc 07:00 ngày ${notificationTime.day}/${notificationTime.month}/${notificationTime.year}'
          );
        }
      } else if (event.eventType == 'user_event') {
        final eventDateTime = _combineEventDateTime(event);

        // Simple notification config
        if (event.simpleNotificationConfig != null) {
          final config = event.simpleNotificationConfig!;
          final timeParts = config.notifyTime.split(':');
          final notifyHour = int.tryParse(timeParts[0]) ?? 7;
          final notifyMinute = int.tryParse(timeParts[1]) ?? 0;

          if (config.notifyOnDay) {
            final notificationTime = DateTime(
              event.eventDate.year,
              event.eventDate.month,
              event.eventDate.day,
              notifyHour,
              notifyMinute,
            );
            if (notificationTime.isAfter(now)) {
              scheduledNotifications.add(
                'Nhắc nhở ngày sự kiện: ${config.notifyTime} ngày ${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}'
              );
            }
          }

          for (final minutesBefore in config.notifyDaysBefore) {
            final notificationTime = eventDateTime.subtract(Duration(minutes: minutesBefore));
            if (notificationTime.isAfter(now)) {
              final daysBefore = (minutesBefore / 1440).round();
              scheduledNotifications.add(
                'Nhắc trước ${daysBefore > 0 ? '$daysBefore ngày' : '${(minutesBefore / 60).round()} giờ'}: ${notificationTime.day}/${notificationTime.month}/${notificationTime.year} ${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')}'
              );
            }
          }
        }

        // Custom reminders
        if (event.customReminders != null) {
          for (final reminder in event.customReminders!) {
            DateTime? notificationTime;

            if (reminder.type == CustomReminderType.countdown) {
              final hours = reminder.countdownHours ?? 0;
              final minutes = reminder.countdownMinutes ?? 0;
              notificationTime = eventDateTime.subtract(
                Duration(hours: hours, minutes: minutes),
              );
            } else if (reminder.type == CustomReminderType.specificDate &&
                       reminder.specificDateTime != null) {
              notificationTime = reminder.specificDateTime!;
            }

            if (notificationTime != null && notificationTime.isAfter(now)) {
              scheduledNotifications.add(
                'Nhắc tùy chỉnh: ${notificationTime.day}/${notificationTime.month}/${notificationTime.year} ${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')}'
              );
            }
          }
        }

        // Default notification
        if (event.simpleNotificationConfig == null &&
            (event.customReminders == null || event.customReminders!.isEmpty)) {
          final defaultNotificationTime = DateTime(
            event.eventDate.year,
            event.eventDate.month,
            event.eventDate.day - 1,
            7, 0,
          );
          if (defaultNotificationTime.isAfter(now)) {
            scheduledNotifications.add(
              'Nhắc mặc định: 07:00 ngày ${defaultNotificationTime.day}/${defaultNotificationTime.month}/${defaultNotificationTime.year} (1 ngày trước)'
            );
          }
        }
      }

      if (scheduledNotifications.isEmpty) {
        return '✅ Đã thử lập lịch thông báo thật, nhưng không có thông báo nào được lập lịch (có thể do thời gian đã qua)';
      }

      // Get current pending notifications count
      final pendingCount = await getPendingNotificationRequests();

      return '✅ ĐÃ LẬP LỊCH THÔNG BÁO THẬT!\n\nDanh sách lịch thông báo:\n${scheduledNotifications.join('\n')}\n\n📱 Tổng số thông báo đang chờ: ${pendingCount.length}';
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to test notification logic', e, stackTrace);
      return 'Lỗi khi test logic thông báo: $e';
    }
  }
}
