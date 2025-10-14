// File: app/modules/daily_event_popup/controllers/daily_event_popup_controller.dart
import 'dart:async';
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/modules/daily_event_popup/views/daily_event_popup_view.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/data/providers/storage_provider.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
// *** THÊM IMPORT CHO EventCategoryService VÀ EventCategory ***
import 'package:nhac_lich_viet/app/services/event_category_service.dart';
import 'package:nhac_lich_viet/app/data/models/event_category_model.dart';
// **********************************************************

class DailyEventPopupController extends GetxController {
  final EventServices _eventServices = Get.find<EventServices>();
  final StorageProvider _storageProvider = Get.find<StorageProvider>();
  // *** THÊM THAM CHIẾU EventCategoryService ***
  final EventCategoryService _categoryService =
      Get.find<EventCategoryService>();
  // ******************************************

  final RxBool _isCheckingPopups = false.obs;
  final RxList<Event> _eventsToShowPopup = <Event>[].obs;
  Timer? _popupDisplayTimer;

  String get _todayDateString =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    LoggerUtils.debug(
        "DailyEventPopupController initialized. Ready to check popups when called.");
  }

  // *** PHƯƠNG THỨC LẤY CATEGORY CHO EVENT (GIỮ NGUYÊN TỪ LƯỢT TRƯỚC) ***
  Future<EventCategory?> getCategoryForEvent(Event event) async {
    if (event.categoryId == null || event.categoryId!.isEmpty) {
      return null;
    }
    try {
      final cachedCategories = await _categoryService.getCachedCategories();
      final foundCategory =
          cachedCategories.firstWhereOrNull((c) => c.id == event.categoryId);
      if (foundCategory != null) {
        return foundCategory;
      }
      // Optional: Fetch from API if not in cache
      // final allCategories = await _categoryService.fetchCategories();
      // return allCategories.firstWhereOrNull((c) => c.id == event.categoryId);
      return null;
    } catch (e) {
      LoggerUtils.error(
          "Error fetching category for event ${event.id} in DailyEventPopupController",
          e);
      return null;
    }
  }
  // **********************************************************************

  void _displayNextPopup() {
    LoggerUtils.info("🔍 [POPUP_DEBUG] _displayNextPopup() called");
    LoggerUtils.info("🔍 [POPUP_DEBUG] _eventsToShowPopup.length: ${_eventsToShowPopup.length}");
    
    if (_eventsToShowPopup.isEmpty) {
      LoggerUtils.debug(
          "DailyEventPopupController: Đã hiển thị tất cả popup cho ngày $_todayDateString.");
      // Chỉ set timestamp nếu đây không phải là force check (hoặc nếu logic của bạn muốn set cả khi force)
      // Hiện tại, để tránh việc force check nhiều lần trong ngày bị block, chúng ta không set lại timestamp ở đây
      // mà sẽ dựa vào điều kiện shouldCheckToday trong checkAndShowEventPopups.
      _isCheckingPopups.value = false;
      return;
    }

    final Event eventToShow = _eventsToShowPopup.first;
    LoggerUtils.info("🔍 [POPUP_DEBUG] Event to show: ${eventToShow.id} - ${eventToShow.title}");
    LoggerUtils.info("🔍 [POPUP_DEBUG] Calling Get.dialog()");

    Get.dialog(
      DailyEventPopupView(event: eventToShow), // Truyền event vào view
      barrierDismissible: false,
    );
    
    LoggerUtils.info("🔍 [POPUP_DEBUG] Get.dialog() called successfully");
  }

  Future<void> handlePopupAction(Event event, bool viewDetails) async {
    await _storageProvider.addShownEventId(event.id);
    LoggerUtils.debug(
        "DailyEventPopupController: Đã đánh dấu eventId ${event.id} là đã hiển thị.");

    // Loại bỏ sự kiện đã xử lý khỏi danh sách chờ
    _eventsToShowPopup.removeWhere((e) => e.id == event.id);

    if (viewDetails) {
      Get.toNamed(Routes.EVENT_DETAIL, arguments: {'event': event})?.then((_) {
        _popupDisplayTimer?.cancel();
        _popupDisplayTimer = Timer(const Duration(milliseconds: 100), () {
          _displayNextPopup();
        });
      });
    } else {
      _popupDisplayTimer?.cancel();
      _popupDisplayTimer = Timer(const Duration(milliseconds: 100), () {
        _displayNextPopup();
      });
    }
  }

  // *** SỬA HÀM checkAndShowEventPopups VỚI forceCheck ***
  Future<void> checkAndShowEventPopups({bool forceCheck = false}) async {
    LoggerUtils.info("🔍 [POPUP_DEBUG] ========== CHECKING POPUP ==========");
    LoggerUtils.info("🔍 [POPUP_DEBUG] forceCheck: $forceCheck");
    LoggerUtils.info("🔍 [POPUP_DEBUG] _isCheckingPopups: ${_isCheckingPopups.value}");
    LoggerUtils.info("🔍 [POPUP_DEBUG] Today date: $_todayDateString");
    
    if (_isCheckingPopups.value && !forceCheck) {
      LoggerUtils.debug(
          "DailyEventPopupController: Đang trong quá trình kiểm tra popups, bỏ qua lần gọi này.");
      return;
    }
    _isCheckingPopups.value = true;
    LoggerUtils.debug(
        "DailyEventPopupController: Bắt đầu kiểm tra và hiển thị popups cho ngày $_todayDateString (forceCheck: $forceCheck)");

    try {
      // Chỉ xóa dữ liệu cũ nếu không phải là forceCheck
      if (!forceCheck) {
        await _storageProvider.clearOldPopupData();
      }

      final lastCheckTimestamp = _storageProvider.getLastPopupCheckTimestamp();
      LoggerUtils.info("🔍 [POPUP_DEBUG] lastCheckTimestamp: $lastCheckTimestamp");
      
      bool shouldCheckToday = true;
      // Nếu không force check VÀ đã check hôm nay rồi, thì không cần check nữa
      if (lastCheckTimestamp != null && !forceCheck) {
        final lastCheckDate =
            DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
        LoggerUtils.info("🔍 [POPUP_DEBUG] lastCheckDate: $lastCheckDate");
        LoggerUtils.info("🔍 [POPUP_DEBUG] currentDate: ${DateTime.now()}");
        
        // Check if system date was changed backwards (time travel detection)
        if (lastCheckDate.isAfter(DateTime.now())) {
          LoggerUtils.info("🔍 [POPUP_DEBUG] Time travel detected! System date changed backwards. Resetting timestamp.");
          await _storageProvider.write('lastPopupCheckTimestamp_dailyEvents', null);
          shouldCheckToday = true;
        } else if (lastCheckDate.year == DateTime.now().year &&
            lastCheckDate.month == DateTime.now().month &&
            lastCheckDate.day == DateTime.now().day) {
          shouldCheckToday = false;
        }
      }

      LoggerUtils.info("🔍 [POPUP_DEBUG] shouldCheckToday: $shouldCheckToday");
      
      if (!shouldCheckToday) {
        LoggerUtils.info(
            "DailyEventPopupController: Đã kiểm tra popup cho ngày $_todayDateString rồi (hoặc không force check).");
        _isCheckingPopups.value = false;
        return;
      }

      final List<Event> todayEvents =
          _eventServices.getAllEventsForDay(DateTime.now());
      LoggerUtils.info("🔍 [POPUP_DEBUG] todayEvents count: ${todayEvents.length}");
      
      // Debug: Log first few events
      if (todayEvents.isNotEmpty) {
        LoggerUtils.info("🔍 [POPUP_DEBUG] First few events:");
        for (var i = 0; i < todayEvents.length.clamp(0, 3); i++) {
          final event = todayEvents[i];
          LoggerUtils.info("🔍 [POPUP_DEBUG] Event ${i + 1}: ${event.id} - ${event.title} - ${event.eventDate}");
        }
      }

      if (todayEvents.isEmpty) {
        // Chỉ set timestamp nếu không phải forceCheck (hoặc nếu bạn muốn đánh dấu là đã check dù force)
        if (!forceCheck) {
          await _storageProvider.setLastPopupCheckTimestamp();
        }
        LoggerUtils.info(
            "DailyEventPopupController: Không có sự kiện nào cho ngày hôm nay.");
        _isCheckingPopups.value = false;
        return;
      }

      final List<String> shownEventIds =
          _storageProvider.getShownEventIdsForDate(_todayDateString);
      LoggerUtils.info("🔍 [POPUP_DEBUG] shownEventIds: $shownEventIds");

      _eventsToShowPopup.value = todayEvents
          .where((event) => !shownEventIds.contains(event.id))
          .toList();
      LoggerUtils.info("🔍 [POPUP_DEBUG] eventsToShowPopup count: ${_eventsToShowPopup.length}");
      
      // Debug: Log events to show
      if (_eventsToShowPopup.isNotEmpty) {
        LoggerUtils.info("🔍 [POPUP_DEBUG] Events to show popup:");
        for (var i = 0; i < _eventsToShowPopup.length.clamp(0, 3); i++) {
          final event = _eventsToShowPopup[i];
          LoggerUtils.info("🔍 [POPUP_DEBUG] ToShow ${i + 1}: ${event.id} - ${event.title}");
        }
      }

      if (_eventsToShowPopup.isNotEmpty) {
        LoggerUtils.info("🔍 [POPUP_DEBUG] Calling _displayNextPopup()");
        _displayNextPopup();
      } else {
        // Nếu không có event nào mới để hiển thị, và là lần check thông thường (không phải force)
        // thì mới cập nhật lastPopupCheckTimestamp.
        if (!forceCheck) {
          await _storageProvider.setLastPopupCheckTimestamp();
        }
        LoggerUtils.info("🔍 [POPUP_DEBUG] No new events to show popup");
        _isCheckingPopups.value = false;
      }
    } catch (e, stackTrace) {
      LoggerUtils.error(
          "DailyEventPopupController: Lỗi trong quá trình checkAndShowEventPopups",
          e,
          stackTrace);
      _isCheckingPopups.value = false; // Quan trọng: reset cờ dù có lỗi
    }
  }
  // ****************************************************

  // --- THÊM PHƯƠNG THỨC MỚI ĐỂ DEBUG ---
  Future<void> forceCheckAndShowEventPopupsForDebugging() async {
    LoggerUtils.debug("DEBUG: Yêu cầu kiểm tra lại popup (forceCheck=true).");
    // Reset cờ _isCheckingPopups để cho phép chạy lại
    _isCheckingPopups.value = false;
    // Gọi hàm check chính với forceCheck = true
    await checkAndShowEventPopups(forceCheck: true);
  }
  
  // --- THÊM PHƯƠNG THỨC ĐỂ RESET TIMESTAMP ---
  Future<void> resetPopupTimestampForDebugging() async {
    LoggerUtils.debug("DEBUG: Resetting popup timestamp for debugging");
    try {
      // Clear timestamp để force check
      await _storageProvider.write('lastPopupCheckTimestamp_dailyEvents', null);
      
      // Clear shown events for today
      final todayString = _todayDateString;
      await _storageProvider.write('shownEventIds_dailyEvents_$todayString', <String>[]);
      
      LoggerUtils.info("🔍 [POPUP_DEBUG] Cleared popup data for debugging");
      
      // Reset the checking flag
      _isCheckingPopups.value = false;
      
      // Force check immediately
      await checkAndShowEventPopups(forceCheck: true);
    } catch (e) {
      LoggerUtils.error("Error resetting popup data", e);
    }
  }
  // --- KẾT THÚC PHƯƠNG THỨC MỚI ---

  @override
  void onClose() {
    _popupDisplayTimer?.cancel();
    super.onClose();
  }
}
