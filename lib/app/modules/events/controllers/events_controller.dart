import 'dart:async';
import 'package:nhac_lich_viet/app/data/models/event_category_model.dart';
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/services/api_refresh_service.dart';
import 'package:nhac_lich_viet/app/services/event_category_service.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nhac_lich_viet/app/modules/detail/services/lunar_service.dart';

/// Input data cho Isolate để xử lý recurring events
class EventMultiOccurrenceInput {
  final List<Event> baseEvents;
  final DateTime currentDate;
  final int pastSearchLimitDays;
  final int futureSearchLimitDays;

  EventMultiOccurrenceInput(
    this.baseEvents,
    this.currentDate,
    this.pastSearchLimitDays,
    this.futureSearchLimitDays,
  );
}

/// Output data từ Isolate
class EventMultiOccurrenceResult {
  final Map<String, List<Event>> relevantOccurrencesMap;
  EventMultiOccurrenceResult(this.relevantOccurrencesMap);
}

/// Hàm tính toán chạy trong Isolate (background thread)
/// Tìm tất cả các occurrence của recurring events trong khoảng thời gian
Future<EventMultiOccurrenceResult> _isolateFindRelevantOccurrences(
    EventMultiOccurrenceInput input) async {
  final List<Event> baseEvents = input.baseEvents;
  final DateTime today = DateTime(
      input.currentDate.year, input.currentDate.month, input.currentDate.day);
  final DateTime pastWindowStart =
      today.subtract(Duration(days: input.pastSearchLimitDays));
  final DateTime futureWindowEnd =
      today.add(Duration(days: input.futureSearchLimitDays));
  final Map<String, List<Event>> occurrencesMap = {};

  for (final event in baseEvents) {
    final String originalEventId = event.id;
    final List<Event> foundOccurrences = [];
    final DateTime eventStartDate = DateTime(
        event.eventDate.year, event.eventDate.month, event.eventDate.day);

    // Nhận diện event âm lịch qua title nếu isLunar không được set
    bool isLikelyLunarEvent = event.isLunar ||
        event.title.toLowerCase().contains('tết') ||
        event.title.toLowerCase().contains('mùng') ||
        event.title.toLowerCase().contains('rằm') ||
        event.title.toLowerCase().contains('âm lịch') ||
        event.title.toLowerCase().contains('giỗ') ||
        event.title.toLowerCase().contains('đoan ngọ') ||
        event.title.toLowerCase().contains('trung thu') ||
        event.title.toLowerCase().contains('vu lan') ||
        event.title.toLowerCase().contains('thần tài') ||
        event.title.toLowerCase().contains('táo quân') ||
        (event.categoryId != null && event.categoryId == 'ngio');

    // Xử lý event không lặp lại
    if (event.repeatType == 'Không lặp lại' ||
        event.repeatType.isEmpty ||
        event.repeatType == 'none') {
      if (!eventStartDate.isBefore(pastWindowStart) &&
          !eventStartDate.isAfter(futureWindowEnd)) {
        foundOccurrences.add(event);
      }
    } else {
      // Xử lý đặc biệt cho user event lặp hàng ngày - chỉ hiển thị ngày tạo
      if (event.eventType == 'user_event' &&
          (event.repeatType == 'daily' || event.repeatType == 'Hằng ngày')) {
        if (!eventStartDate.isBefore(pastWindowStart) &&
            !eventStartDate.isAfter(futureWindowEnd)) {
          foundOccurrences.add(event);
        }
      } else {
        // Xử lý recurring events thông thường
        DateTime? nearestPastOccurrenceDate;
        DateTime? todayOccurrenceDate;
        DateTime? nearestFutureOccurrenceDate;

        // Kiểm tra event có xảy ra hôm nay không
        if (EventServices.staticDoesEventOccurOnDate(event, today)) {
          todayOccurrenceDate = today;
          foundOccurrences.add(
              _staticCreateAdjustedRecurringEvent(event, todayOccurrenceDate));
        }

        // Tìm điểm bắt đầu cho tìm kiếm future events
        DateTime searchDateFuture = eventStartDate.isAfter(today)
            ? eventStartDate
            : today.add(const Duration(days: 1));

        if (!eventStartDate.isAfter(today)) {
          int findStartBreak = 0;
          DateTime checkDate = eventStartDate;
          while (checkDate.isBefore(searchDateFuture) &&
              findStartBreak < 366 * 5) {
            final next =
                _staticGetNextOccurrenceDate(event.repeatType, checkDate, event);
            if (next == null || next.isAtSameMomentAs(checkDate)) break;
            checkDate = next;
            findStartBreak++;
          }
          searchDateFuture = checkDate;
          if (findStartBreak >= 366 * 5) {
            LoggerUtils.warning(
                "Could not find starting future date efficiently for event ${event.id}");
            searchDateFuture = today.add(const Duration(days: 1));
          }
        }

        // === TÌM KIẾM FUTURE EVENTS ===

        // Với event âm lịch hàng năm: tìm cả tháng thường VÀ tháng nhuận
        if (isLikelyLunarEvent &&
            (event.repeatType == 'yearly' || event.repeatType == 'Hằng năm')) {
          DateTime searchDate = today.add(const Duration(days: 1));
          int dayCount = 0;
          Event? normalMonthOccurrence;
          Event? leapMonthOccurrence;

          // Tìm trong vòng 400 ngày (đủ cover cả năm âm lịch có tháng nhuận)
          while (!searchDate.isAfter(futureWindowEnd) && dayCount < 400) {
            if (EventServices.staticDoesEventOccurOnDate(event, searchDate)) {
              final occurrence =
                  _staticCreateAdjustedRecurringEvent(event, searchDate);

              // Phân biệt tháng nhuận vs tháng thường dựa vào title
              if (occurrence.title.contains('nhuận')) {
                leapMonthOccurrence = occurrence;
              } else {
                normalMonthOccurrence ??= occurrence;
              }

              // Nếu đã tìm thấy cả 2, dừng tìm kiếm
              if (normalMonthOccurrence != null &&
                  leapMonthOccurrence != null) {
                break;
              }
            }
            searchDate = searchDate.add(const Duration(days: 1));
            dayCount++;
          }

          // Thêm CẢ HAI occurrence nếu tìm thấy (để hiển thị cả 2)
          if (normalMonthOccurrence != null) {
            foundOccurrences.add(normalMonthOccurrence);
          }
          if (leapMonthOccurrence != null) {
            foundOccurrences.add(leapMonthOccurrence);
          }
        }
        // Với event âm lịch khác (không phải yearly): tìm occurrence gần nhất
        else if (isLikelyLunarEvent) {
          DateTime searchDate = today.add(const Duration(days: 1));
          int dayCount = 0;

          while (!searchDate.isAfter(futureWindowEnd) &&
              dayCount < input.futureSearchLimitDays) {
            if (EventServices.staticDoesEventOccurOnDate(event, searchDate)) {
              final occurrence =
                  _staticCreateAdjustedRecurringEvent(event, searchDate);
              foundOccurrences.add(occurrence);
              break;
            }
            searchDate = searchDate.add(const Duration(days: 1));
            dayCount++;
          }
        }
        // Event dương lịch: tìm occurrence gần nhất
        else {
          int futureSafetyBreak = 0;
          while (!searchDateFuture.isAfter(futureWindowEnd) &&
              futureSafetyBreak < (input.futureSearchLimitDays + 10)) {
            if (EventServices.staticDoesEventOccurOnDate(
                event, searchDateFuture)) {
              nearestFutureOccurrenceDate = searchDateFuture;
              foundOccurrences.add(_staticCreateAdjustedRecurringEvent(
                  event, nearestFutureOccurrenceDate));
              break;
            }
            final next = _staticGetNextOccurrenceDate(
                event.repeatType, searchDateFuture, event);
            if (next == null || next.isAtSameMomentAs(searchDateFuture)) break;
            searchDateFuture = DateTime(next.year, next.month, next.day);
            futureSafetyBreak++;
            if (futureSafetyBreak >= input.futureSearchLimitDays + 10) {
              LoggerUtils.warning(
                  "Future occurrence search limit reached for event ${event.id}");
            }
          }
        }

        // === TÌM KIẾM PAST EVENTS ===

        // Event âm lịch hàng năm: ưu tiên tháng nhuận nếu có
        if (isLikelyLunarEvent &&
            (event.repeatType == 'yearly' || event.repeatType == 'Hằng năm')) {
          DateTime searchDatePast = today.subtract(const Duration(days: 1));
          int dayCount = 0;
          Event? normalMonthOccurrence;
          Event? leapMonthOccurrence;

          while (!searchDatePast.isBefore(pastWindowStart) &&
              dayCount < input.pastSearchLimitDays) {
            if (EventServices.staticDoesEventOccurOnDate(
                event, searchDatePast)) {
              final occurrence =
                  _staticCreateAdjustedRecurringEvent(event, searchDatePast);

              // Ưu tiên tháng nhuận cho quá khứ
              if (occurrence.title.contains('nhuận')) {
                leapMonthOccurrence = occurrence;
                break; // Dừng ngay khi tìm thấy tháng nhuận
              } else {
                normalMonthOccurrence ??= occurrence;
              }
            }
            searchDatePast = searchDatePast.subtract(const Duration(days: 1));
            dayCount++;
          }

          // Ưu tiên tháng nhuận, fallback về tháng thường
          if (leapMonthOccurrence != null) {
            foundOccurrences.add(leapMonthOccurrence);
          } else if (normalMonthOccurrence != null) {
            foundOccurrences.add(normalMonthOccurrence);
          }
        }
        // Event âm lịch khác: tìm occurrence gần nhất
        else if (isLikelyLunarEvent) {
          DateTime searchDatePast = today.subtract(const Duration(days: 1));
          int dayCount = 0;

          while (!searchDatePast.isBefore(pastWindowStart) &&
              dayCount < input.pastSearchLimitDays) {
            if (EventServices.staticDoesEventOccurOnDate(
                event, searchDatePast)) {
              final occurrence =
                  _staticCreateAdjustedRecurringEvent(event, searchDatePast);
              foundOccurrences.add(occurrence);
              break;
            }
            searchDatePast = searchDatePast.subtract(const Duration(days: 1));
            dayCount++;
          }
        }
        // Event dương lịch
        else {
          DateTime searchDatePast = today.subtract(const Duration(days: 1));
          int pastSafetyBreak = 0;
          while (!searchDatePast.isBefore(pastWindowStart) &&
              pastSafetyBreak < (input.pastSearchLimitDays + 10)) {
            if (searchDatePast.isBefore(eventStartDate)) break;
            if (EventServices.staticDoesEventOccurOnDate(
                event, searchDatePast)) {
              nearestPastOccurrenceDate = searchDatePast;
              foundOccurrences.add(_staticCreateAdjustedRecurringEvent(
                  event, nearestPastOccurrenceDate));
              break;
            }
            searchDatePast = searchDatePast.subtract(const Duration(days: 1));
            pastSafetyBreak++;
            if (pastSafetyBreak >= input.pastSearchLimitDays + 10) {
              LoggerUtils.warning(
                  "Past occurrence search limit reached for event ${event.id}");
            }
          }
        }
      }
    }

    if (foundOccurrences.isNotEmpty) {
      occurrencesMap[originalEventId] = foundOccurrences;
    }
  }
  return EventMultiOccurrenceResult(occurrencesMap);
}

/// Tạo event occurrence mới từ event gốc với ngày được điều chỉnh
/// Xử lý đặc biệt cho tháng nhuận âm lịch
Event _staticCreateAdjustedRecurringEvent(
    Event originalEvent, DateTime targetDate) {
  String adjustedTitle = originalEvent.title;
  String adjustedRepeatType = originalEvent.repeatType;

  // Xử lý tháng nhuận cho event âm lịch
  if (originalEvent.isLunar && originalEvent.originalLunarDate != null) {
    try {
      final targetMonth = targetDate.month;
      final targetYear = targetDate.year;
      final targetDay = targetDate.day;

      bool isLikelyLeapMonth = false;

      // Heuristic để detect tháng nhuận dựa vào dương lịch
      // Năm 2025: Tháng 6 nhuận từ 24/7 đến 22/8
      if (targetYear == 2025) {
        if ((targetMonth == 7 && targetDay >= 24) ||
            (targetMonth == 8 && targetDay <= 22)) {
          if (originalEvent.originalLunarDate != null) {
            final lunarDay = originalEvent.originalLunarDate!.day;
            final lunarMonth = originalEvent.originalLunarDate!.month;

            // Chỉ áp dụng cho Mùng 1 và Rằm tháng 6
            if (lunarMonth == 6 && (lunarDay == 1 || lunarDay == 15)) {
              isLikelyLeapMonth = true;
            }
          }
        }
      }

      // TODO: Thêm logic cho các năm khác nếu cần
      // Năm 2028: Tháng 5 nhuận
      // Năm 2031: Tháng 3 nhuận

      if (isLikelyLeapMonth) {
        // Thêm "nhuận" vào title
        final RegExp pattern = RegExp(r'tháng (\d+) Âm lịch');
        final match = pattern.firstMatch(adjustedTitle);

        if (match != null) {
          final monthNumber = match.group(1);
          adjustedTitle = adjustedTitle.replaceAll(
              'tháng $monthNumber Âm lịch', 'tháng $monthNumber nhuận Âm lịch');
        } else {
          adjustedTitle = '${originalEvent.title} (Tháng nhuận)';
        }

        // Tháng nhuận không lặp lại
        adjustedRepeatType = 'none';
      }
    } catch (e) {
      // Silent fail trong isolate
    }
  }

  return originalEvent.copyWith(
    id: '${originalEvent.id}_${DateFormat('yyyyMMdd').format(targetDate)}',
    title: adjustedTitle,
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
    subtitle: originalEvent.subtitle,
    description: originalEvent.description,
    detail: originalEvent.detail,
    eventType: originalEvent.eventType,
    isNotify: originalEvent.isNotify,
    eventTime: originalEvent.eventTime,
    repeatType: adjustedRepeatType,
    iconUrl: originalEvent.iconUrl,
    bannerUrl: originalEvent.bannerUrl,
    wishes: originalEvent.wishes,
    showOnCalendar: originalEvent.showOnCalendar,
    showNotificationOnOpen: originalEvent.showNotificationOnOpen,
    categoryId: originalEvent.categoryId,
    simpleNotificationConfig: originalEvent.simpleNotificationConfig,
  );
}

/// Tính ngày occurrence tiếp theo dựa vào repeat type
DateTime? _staticGetNextOccurrenceDate(String repeatType, DateTime currentDate,
    [Event? event]) {
  try {
    final currentDayOnly =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    // Xử lý đặc biệt cho event âm lịch
    if (event != null && event.isLunar && event.originalLunarDate != null) {
      switch (repeatType) {
        case 'daily':
        case 'Hằng ngày':
          return currentDayOnly.add(const Duration(days: 1));
        case 'weekly':
        case 'Hằng tuần':
          return currentDayOnly.add(const Duration(days: 7));
        case 'monthly':
        case 'Hằng tháng':
          // Âm lịch: khoảng 29.5 ngày/tháng
          return currentDayOnly.add(const Duration(days: 25));
        case 'yearly':
        case 'Hằng năm':
          // Âm lịch: khoảng 354 ngày/năm
          return currentDayOnly.add(const Duration(days: 350));
        default:
          return null;
      }
    }

    // Logic dương lịch
    switch (repeatType) {
      case 'daily':
      case 'Hằng ngày':
        return currentDayOnly.add(const Duration(days: 1));
      case 'weekly':
      case 'Hằng tuần':
        return currentDayOnly.add(const Duration(days: 7));
      case 'monthly':
      case 'Hằng tháng':
        int nextMonth = currentDayOnly.month + 1;
        int nextYear = currentDayOnly.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        try {
          return DateTime(nextYear, nextMonth, currentDayOnly.day);
        } catch (e) {
          return DateTime(nextYear, nextMonth + 1, 0);
        }
      case 'yearly':
      case 'Hằng năm':
        int nextYear = currentDayOnly.year + 1;
        // Xử lý 29/2 năm nhuận
        if (currentDayOnly.month == 2 && currentDayOnly.day == 29) {
          bool isLeap(int year) =>
              (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
          while (!isLeap(nextYear)) {
            nextYear++;
          }
          return DateTime(nextYear, 2, 29);
        } else {
          try {
            return DateTime(nextYear, currentDayOnly.month, currentDayOnly.day);
          } catch (e) {
            LoggerUtils.error("Error creating yearly occurrence", e);
            try {
              return DateTime(nextYear, currentDayOnly.month + 1, 0);
            } catch (e2) {
              return null;
            }
          }
        }
      default:
        return null;
    }
  } catch (e) {
    LoggerUtils.error("Error getting next occurrence date", e);
    return null;
  }
}

class _CategorizedEvents {
  final List<Event> past;
  final List<Event> today;
  final List<Event> upcoming;

  _CategorizedEvents({
    required this.past,
    required this.today,
    required this.upcoming,
  });
}

/// Controller quản lý danh sách sự kiện
class EventsController extends GetxController {
  // Services
  final EventServices _eventServices = Get.find<EventServices>();
  final EventCategoryService _categoryService =
      Get.find<EventCategoryService>();
  final ApiRefreshService _apiRefreshService = Get.find<ApiRefreshService>();

  // Observable lists - hiển thị theo filter
  final RxList<Event> pastEvents = <Event>[].obs;
  final RxList<Event> todayEvents = <Event>[].obs;
  final RxList<Event> upcomingEvents = <Event>[].obs;
  final RxList<Event> upcomingEventsWithoutFilter = <Event>[].obs;

  // Store all events without filter (dùng cho PageView)
  final RxList<Event> allPastEvents = <Event>[].obs;
  final RxList<Event> allTodayEvents = <Event>[].obs;
  final RxList<Event> allUpcomingEvents = <Event>[].obs;

  // State management
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isError = false.obs;
  final RxString selectedFilter = 'Tất cả'.obs;

  // Categories
  final RxList<EventCategory> eventCategories = <EventCategory>[].obs;
  final RxList<Map<String, String>> uiFilterTabs = <Map<String, String>>[].obs;

  // Internal data
  final RxMap<String, List<Event>> _occurrencesByOriginalId =
      <String, List<Event>>{}.obs;

  // Search limits
  final int pastSearchLimitDays = 30;
  final int futureSearchLimitDays = 365 * 2;

  // Flags
  bool _isProcessingEvents = false;

  // Subscriptions
  StreamSubscription? _eventServiceSubscription;
  Worker? _categoryWorker;

  @override
  void onInit() async {
    super.onInit();

    // Handle initial category filter from arguments
    if (Get.arguments != null && Get.arguments['category'] != null) {
      final initialCategory = Get.arguments['category'] as EventCategory;
      selectedFilter.value = initialCategory.title;
    }

    // Set loading state initially
    isLoading.value = true;

    // OFFLINE-FIRST: Load cache immediately
    _loadCacheImmediate();

    // Luôn dựng tab mặc định để UI hiển thị ngay cả khi chưa có category
    _buildUiFilterTabs();

    // Load categories (cache trước, sau đó API)
    await _loadCategories();
    _buildUiFilterTabs();

    // Background tasks
    loadEventsInBackground();

    // Watch for category changes
    _categoryWorker = ever(eventCategories, (_) {
      LoggerUtils.debug('eventCategories changed, rebuilding UI filter tabs.');
      _buildUiFilterTabs();
    });

    // Subscribe to event changes
    _subscribeToEventChanges();

    // Register network reconnection callback
    _apiRefreshService.registerRefreshCallback(_onNetworkReconnected);
  }

  @override
  void onClose() {
    _eventServiceSubscription?.cancel();
    _categoryWorker?.dispose();
    _apiRefreshService.unregisterRefreshCallback(_onNetworkReconnected);
    super.onClose();
  }

  /// Subscribe to event changes stream
  void _subscribeToEventChanges() {
    _eventServiceSubscription = _eventServices.eventsStream.listen((_) {
      LoggerUtils.debug('EventsController received event update signal.');
      loadEventsInBackground();
    }, onError: (error) {
      LoggerUtils.error('Error listening to event stream', error);
    });
  }

  /// Loại bỏ sự kiện khỏi danh sách hiện tại ngay sau khi xóa
  void removeEventById(String originalEventId) {
    bool changed = false;

    bool _removeFromRxList(RxList<Event> list) {
      final before = list.length;
      list.removeWhere((event) =>
          event.id == originalEventId ||
          (event.originalEventId != null &&
              event.originalEventId == originalEventId));
      if (list.length != before) {
        list.refresh();
        return true;
      }
      return false;
    }

    changed |= _removeFromRxList(pastEvents);
    changed |= _removeFromRxList(todayEvents);
    changed |= _removeFromRxList(upcomingEvents);
    changed |= _removeFromRxList(upcomingEventsWithoutFilter);
    changed |= _removeFromRxList(allPastEvents);
    changed |= _removeFromRxList(allTodayEvents);
    changed |= _removeFromRxList(allUpcomingEvents);

    if (_occurrencesByOriginalId.containsKey(originalEventId)) {
      _occurrencesByOriginalId.remove(originalEventId);
      _occurrencesByOriginalId.refresh();
      changed = true;
    }

    if (changed) {
      LoggerUtils.debug(
          'removeEventById applied for $originalEventId, lists updated immediately.');
    } else {
      LoggerUtils.debug(
          'removeEventById found no matching items for $originalEventId.');
    }
  }

  /// Load categories from cache and API
  Future<void> _loadCategories({bool waitForNetwork = true}) async {
    List<EventCategory> categoriesFromCache = [];

    // Load from cache first để dùng được khi offline
    try {
      categoriesFromCache = await _categoryService.getCachedCategories();
      if (categoriesFromCache.isNotEmpty) {
        eventCategories.value = categoriesFromCache.reversed.toList();
        _buildUiFilterTabs();
      }
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Error loading cached categories in EventsController', e, stackTrace);
    }

    Future<void> fetchFromApi() async {
      try {
        final categoriesFromApi = await _categoryService.fetchCategories();
        if (categoriesFromApi.isNotEmpty) {
          final shouldUpdate = categoriesFromCache.isEmpty ||
              categoriesFromApi.length != categoriesFromCache.length ||
              !_areCategoriesIdentical(
                  categoriesFromCache, categoriesFromApi);

          if (shouldUpdate) {
            eventCategories.value = categoriesFromApi.reversed.toList();
            await _categoryService.cacheCategories(categoriesFromApi);
          }
        }
      } catch (e, stackTrace) {
        LoggerUtils.error(
            'Error fetching categories from API in EventsController', e, stackTrace);
      }
    }

    if (waitForNetwork) {
      await fetchFromApi();
    } else {
      unawaited(fetchFromApi());
    }
  }

  bool _areCategoriesIdentical(
      List<EventCategory> cached, List<EventCategory> remote) {
    if (cached.length != remote.length) return false;

    for (int i = 0; i < cached.length; i++) {
      final cachedItem = cached[i];
      final remoteItem = remote[i];
      if (cachedItem.id != remoteItem.id ||
          cachedItem.title != remoteItem.title ||
          cachedItem.iconUrl != remoteItem.iconUrl ||
          cachedItem.bannerUrl != remoteItem.bannerUrl) {
        return false;
      }
    }

    return true;
  }

  /// Load cache immediately with retry logic
  void _loadCacheImmediate() async {
    int retryCount = 0;
    while (retryCount < 10) {
      // Max 1 second (10 x 100ms)
      try {
        final cachedEvents = _eventServices.getAllEvents();

        if (cachedEvents.isNotEmpty || retryCount > 5) {
          if (cachedEvents.isNotEmpty) {
            LoggerUtils.debug(
                'Loading ${cachedEvents.length} cached events immediately');

            // Always show cached data instantly for a responsive first paint
            _loadCacheSimple(cachedEvents);
            isLoading.value = false;

            // Run the heavier isolate processing in the background to refine data
            if (!_isProcessingEvents) {
              _isProcessingEvents = true;
              final cachedCopy =
                  cachedEvents.map((e) => e.copyWith()).toList();
              Future.microtask(() async {
                try {
                  final currentDate = DateTime.now();
                  final EventMultiOccurrenceResult result = await compute(
                    _isolateFindRelevantOccurrences,
                    EventMultiOccurrenceInput(
                      cachedCopy,
                      currentDate,
                      pastSearchLimitDays,
                      futureSearchLimitDays,
                    ),
                  );

                  _occurrencesByOriginalId.value =
                      result.relevantOccurrencesMap;
                  _applyFilterAndCategorize();

                  LoggerUtils.debug(
                      '🔥 OFFLINE: Cache processed - upcoming=${upcomingEvents.length}, today=${todayEvents.length}, past=${pastEvents.length}');
                } catch (e, stackTrace) {
                  LoggerUtils.error(
                      'Error processing cache in background, keeping simple cache data',
                      e,
                      stackTrace);
                } finally {
                  _isProcessingEvents = false;
                }
              });
            } else {
              LoggerUtils.debug(
                  '⏭️ SKIP: Events already being processed, simple cache shown');
            }
          } else {
            LoggerUtils.debug('No cached events found after retries');
            isLoading.value = false;
          }
          break;
        }

        retryCount++;
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e, stackTrace) {
        if (e.toString().contains('LateInitializationError') &&
            retryCount < 10) {
          retryCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }

        LoggerUtils.error('Error loading cache immediate', e, stackTrace);
        isLoading.value = false;
        break;
      }
    }
  }

  /// Simple fallback logic khi isolate processing fails
  void _loadCacheSimple(List<Event> cachedEvents) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Event> quickUpcoming = [];
    final List<Event> quickToday = [];
    final List<Event> quickPast = [];

    for (final event in cachedEvents) {
      final eventDate = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);

      if (eventDate.isAfter(today)) {
        quickUpcoming.add(event);
      } else if (eventDate.isAtSameMomentAs(today)) {
        quickToday.add(event);
      } else if (quickPast.length < 3) {
        quickPast.add(event);
      }
    }

    // Sort and update
    quickUpcoming.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    quickToday.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    quickPast.sort((a, b) => b.eventDate.compareTo(a.eventDate));

    upcomingEvents.value = quickUpcoming;
    todayEvents.value = quickToday;
    pastEvents.value = quickPast;
    upcomingEventsWithoutFilter.value = List.from(quickUpcoming);

    // Also update the master lists so các tab khác hiển thị ngay lập tức
    allUpcomingEvents.value = List.from(quickUpcoming);
    allTodayEvents.value = List.from(quickToday);
    allPastEvents.value = List.from(quickPast);

    LoggerUtils.debug(
        '📦 FALLBACK: Simple cache - upcoming=${quickUpcoming.length}, today=${quickToday.length}, past=${quickPast.length}');
  }

  /// Build filter tabs từ categories
  void _buildUiFilterTabs() {
    final List<Map<String, String>> tabs = [
      {'id': 'all', 'title': 'Tất cả'},
    ];
    for (var category in eventCategories) {
      // Filter out system events category
      if (category.title != 'Sự kiện hệ thống') {
        tabs.add({'id': category.id, 'title': category.title});
      }
    }
    uiFilterTabs.value = tabs;
  }

  /// Load và process events trong background
  Future<void> loadEventsInBackground() async {
    if (_isProcessingEvents) {
      LoggerUtils.debug(
          '⏭️ SKIP: Background processing skipped, already processing');
      return;
    }

    isError.value = false;
    errorMessage.value = '';

    _isProcessingEvents = true;
    try {
      final List<Event> baseEvents = _eventServices.getAllEvents();
      final List<Event> eventsToSend =
          baseEvents.map((e) => e.copyWith()).toList();
      final DateTime currentDate = DateTime.now();

      final EventMultiOccurrenceResult result = await compute(
        _isolateFindRelevantOccurrences,
        EventMultiOccurrenceInput(
            eventsToSend, currentDate, pastSearchLimitDays, futureSearchLimitDays),
      );

      _occurrencesByOriginalId.value = result.relevantOccurrencesMap;
      _applyFilterAndCategorize();

      LoggerUtils.debug(
          '🌐 ONLINE: Background processed - upcoming=${upcomingEvents.length}, today=${todayEvents.length}, past=${pastEvents.length}');
    } catch (e, stackTrace) {
      isError.value = true;
      errorMessage.value = 'Lỗi xử lý sự kiện: ${e.toString()}';
      LoggerUtils.error('Error processing events in background', e, stackTrace);
      _clearEventLists();
    } finally {
      _isProcessingEvents = false;
    }
  }

  _CategorizedEvents _computeCategorizedEvents({String? categoryId}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Event> finalPast = [];
    final List<Event> finalToday = [];
    final List<Event> finalUpcoming = [];
    final Set<String> addedPastOriginalIds = {};

    _occurrencesByOriginalId.forEach((originalId, relevantOccurrences) {
      final originalEvent = _eventServices.getEventById(originalId);
      if (originalEvent == null) return;

      if (categoryId != null && originalEvent.categoryId != categoryId) {
        return;
      }

      Event? pastOccurrence;
      Event? todayOccurrence;
      List<Event> futureOccurrences = [];

      for (final occ in relevantOccurrences) {
        final occDate =
            DateTime(occ.eventDate.year, occ.eventDate.month, occ.eventDate.day);
        if (occDate.isBefore(today)) {
          if (pastOccurrence == null ||
              occDate.isAfter(pastOccurrence.eventDate)) {
            pastOccurrence = occ;
          }
        } else if (EventServices.isSameDay(occDate, today)) {
          todayOccurrence = occ;
        } else {
          futureOccurrences.add(occ);
        }
      }

      if (pastOccurrence != null) finalPast.add(pastOccurrence);
      if (todayOccurrence != null) finalToday.add(todayOccurrence);

      if (futureOccurrences.isNotEmpty) {
        futureOccurrences.sort((a, b) => a.eventDate.compareTo(b.eventDate));

        bool isLunarEvent = originalEvent.isLunar ||
            originalEvent.title.toLowerCase().contains('âm lịch') ||
            originalEvent.title.toLowerCase().contains('mùng') ||
            originalEvent.title.toLowerCase().contains('rằm');

        if (isLunarEvent && futureOccurrences.length > 1) {
          bool hasLeapMonth =
              futureOccurrences.any((e) => e.title.contains('nhuận'));
          bool hasRegularMonth =
              futureOccurrences.any((e) => !e.title.contains('nhuận'));

          if (hasLeapMonth && hasRegularMonth) {
            for (var occ in futureOccurrences.take(2)) {
              finalUpcoming.add(occ);
            }
          } else {
            finalUpcoming.add(futureOccurrences.first);
          }
        } else {
          finalUpcoming.add(futureOccurrences.first);
        }
      }
    });

    finalPast.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    final List<Event> limitedPastEvents = [];
    for (final occurrence in finalPast) {
      if (limitedPastEvents.length >= 3) break;
      final originalId = occurrence.originalEventId ?? occurrence.id;
      if (!addedPastOriginalIds.contains(originalId)) {
        limitedPastEvents.add(occurrence);
        addedPastOriginalIds.add(originalId);
      }
    }

    finalToday.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    finalUpcoming.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    limitedPastEvents.sort((b, a) => b.eventDate.compareTo(a.eventDate));

    return _CategorizedEvents(
      past: limitedPastEvents,
      today: finalToday,
      upcoming: finalUpcoming,
    );
  }

  /// Apply filter và categorize events
  void _applyFilterAndCategorize() {
    final filterTitle = selectedFilter.value;

    String? selectedCategoryId;
    if (filterTitle != 'Tất cả') {
      final selectedCategory =
          eventCategories.firstWhereOrNull((cat) => cat.title == filterTitle);
      selectedCategoryId = selectedCategory?.id;
    }

    final currentResult =
        _computeCategorizedEvents(categoryId: selectedCategoryId);
    pastEvents.value = currentResult.past;
    todayEvents.value = currentResult.today;
    upcomingEvents.value = currentResult.upcoming;

    final masterResult = _computeCategorizedEvents();
    allPastEvents.value = List.from(masterResult.past);
    allTodayEvents.value = List.from(masterResult.today);
    allUpcomingEvents.value = List.from(masterResult.upcoming);
    upcomingEventsWithoutFilter.value = List.from(masterResult.upcoming);
  }

  void _clearEventLists() {
    pastEvents.clear();
    todayEvents.clear();
    upcomingEvents.clear();
    upcomingEventsWithoutFilter.clear();
    _occurrencesByOriginalId.clear();
  }

  void filterEventsBy(String filterTitle) {
    if (selectedFilter.value != filterTitle) {
      selectedFilter.value = filterTitle;
      _applyFilterAndCategorize();
    }
  }

  /// Trigger manual refresh without blocking the pull-to-refresh spinner
  /// while heavy background processing runs.
  Future<void> refreshData() async {
    await _loadCategories(waitForNetwork: false);
    unawaited(loadEventsInBackground());
  }

  /// Handle network reconnection
  void _onNetworkReconnected() {
    LoggerUtils.info(
        '📶 Network reconnected - refreshing events and categories...');
    refreshData();
  }

  void goToAddEvent() {
    Get.toNamed(Routes.ADD_EVENT);
  }

  /// Navigate to event detail page
  /// If event is provided, shows event details. Otherwise, shows date details
  void goToEventDetail(DateTime date, {bool? isLeapMonth, Event? event}) {
    if (event != null) {
      // Navigate to event detail with event object
      Get.toNamed(Routes.EVENT_DETAIL, arguments: {'event': event});

      if (event.title.contains('nhuận')) {
        LoggerUtils.debug(
            '🌙 Navigating to event detail with leap month event: ${event.title}');
      }
    } else {
      // No event provided - navigate to event detail with date
      LoggerUtils.warning(
          'goToEventDetail called without event, navigating with date only');
      Get.toNamed(Routes.EVENT_DETAIL, arguments: {'date': date});
    }
  }

  String getLunarDateString(DateTime date) {
    try {
      final lunarDate = LunarService.getSolarToLunar(date);
      return '${lunarDate.day.toString().padLeft(2, '0')}-${lunarDate.month} âm lịch';
    } catch (e) {
      return '';
    }
  }

  String getDaysRemainingText(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay =
        DateTime(eventDate.year, eventDate.month, eventDate.day);
    final difference = eventDay.difference(today).inDays;

    if (difference < 0) {
      final daysAgo = difference.abs();
      if (daysAgo == 1) return 'Hôm qua';
      if (daysAgo == 2) return '2 ngày trước';
      return '$daysAgo ngày trước';
    } else if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Ngày mai';
    } else if (difference == 2) {
      return '2 ngày nữa';
    } else {
      return '$difference ngày nữa';
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  void filterEventsByTitle(String categoryTitle) {
    // Block system events filtering
    if (categoryTitle == 'Sự kiện hệ thống') {
      LoggerUtils.warning(
          "System events filtering is disabled. Defaulting to 'Tất cả'.");
      selectedFilter.value = 'Tất cả';
      _applyFilterAndCategorize();
      return;
    }

    if (eventCategories.isEmpty) {
      LoggerUtils.warning(
          "Event categories not loaded yet. Cannot filter by title: $categoryTitle");
      selectedFilter.value = 'Tất cả';
    } else {
      final categoryExists =
          eventCategories.any((cat) => cat.title == categoryTitle);
      if (categoryExists) {
        selectedFilter.value = categoryTitle;
      } else {
        LoggerUtils.warning(
            "Category with title '$categoryTitle' not found. Defaulting to 'Tất cả'.");
        selectedFilter.value = 'Tất cả';
      }
    }
    _applyFilterAndCategorize();
  }

  String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Hai';
      case 2:
        return 'Ba';
      case 3:
        return 'Tư';
      case 4:
        return 'Năm';
      case 5:
        return 'Sáu';
      case 6:
        return 'Bảy';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }
}
