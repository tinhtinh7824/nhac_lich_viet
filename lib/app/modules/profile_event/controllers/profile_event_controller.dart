// modules/profile_event/controllers/profile_event_controller.dart
import 'package:nhac_lich_viet/app/data/models/event_category_model.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/services/event_category_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:nhac_lich_viet/app/utils/date_utils.dart' as app_date_utils;

class ProfileEventController extends GetxController {
  final EventServices eventServices = Get.find<EventServices>();
  final EventCategoryService categoryService = Get.find<EventCategoryService>();

  // Events list
  final RxList<Event> events = <Event>[].obs;
  final RxList<Event> filteredEvents = <Event>[].obs;
  final RxList<Event> allUserEvents =
      <Event>[].obs; // All user events for PageView

  // Categories
  final RxList<EventCategory> eventCategories = <EventCategory>[].obs;
  final RxString selectedCategoryTitle =
      RxString('Tất cả'); // Mặc định là "Tất cả"

  // Loading state
  final RxBool isLoading = false.obs;

  // Selected tab index
  final RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadEvents();
  }

  // Loading management
  void _startLoading() {
    isLoading.value = true;
  }

  void _stopLoading() {
    isLoading.value = false;
  }

  // Load categories from service
  Future<void> loadCategories() async {
    try {
      var cachedCategories = await categoryService.getCachedCategories();

      if (cachedCategories.isNotEmpty) {
        eventCategories.value = cachedCategories;
      } else {
        final fetchedCategories = await categoryService.fetchCategories();
        if (fetchedCategories.isNotEmpty) {
          eventCategories.value = fetchedCategories;
          await categoryService.cacheCategories(fetchedCategories);
        }
      }
    } catch (e) {
      LoggerUtils.error('Error loading categories', e);
    }
  }

  // Load events and filter
  void loadEvents() {
    _startLoading();
    try {
      final userEvents = eventServices.getAllUserEvents();
      events.value = userEvents;
      allUserEvents.value = userEvents; // Store all events for PageView
      _filterEvents();
      _stopLoading();
    } catch (e) {
      LoggerUtils.error('Error loading events', e);
      showError('Có lỗi khi tải dữ liệu sự kiện. Vui lòng thử lại.');
      _stopLoading();
    }
  }

  // Refresh events
  Future<void> refreshEvents() async {
    try {
      final userEvents = eventServices.getAllUserEvents();
      events.value = userEvents;
      allUserEvents.value = userEvents; // Update all events for PageView
      _filterEvents();
    } catch (e) {
      LoggerUtils.error('Error refreshing events', e);
      showError('Có lỗi khi tải lại dữ liệu sự kiện. Vui lòng thử lại.');
    }
  }

  // Filter events by category title
  void _filterEvents() {
    List<Event> eventsToFilter = [];

    if (selectedCategoryTitle.value == 'Tất cả') {
      eventsToFilter = List.from(events);
    } else {
      final selectedCategory = eventCategories
          .firstWhereOrNull((cat) => cat.title == selectedCategoryTitle.value);

      if (selectedCategory != null) {
        eventsToFilter = events
            .where((event) => event.categoryId == selectedCategory.id)
            .toList();
      } else {
        eventsToFilter = [];
        LoggerUtils.warning(
            'Category not found for title: ${selectedCategoryTitle.value} during filtering. Displaying empty list for this category.');
      }
    }

    eventsToFilter.sort((a, b) {
      final DateTime dateA =
          DateTime(a.eventDate.year, a.eventDate.month, a.eventDate.day);
      final DateTime dateB =
          DateTime(b.eventDate.year, b.eventDate.month, b.eventDate.day);
      return dateA.compareTo(dateB);
    });

    filteredEvents.value = eventsToFilter;
  }

  // Chọn category bằng title
  void selectCategory(String categoryTitle, int index) {
    selectedCategoryTitle.value = categoryTitle;
    selectedTabIndex.value = index;
    _filterEvents();
  }

  // Tính ngày còn lại và hiển thị theo định dạng thân thiện
  String calculateRemainingDays(DateTime eventDate) {
    DateTime now = DateTime.now();
    DateTime targetDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    );
    DateTime today = DateTime(now.year, now.month, now.day);

    int daysRemaining = targetDate.difference(today).inDays;

    if (daysRemaining == 0) {
      return 'Hôm nay';
    } else if (daysRemaining == 1) {
      return 'Ngày mai';
    } else if (daysRemaining == 2) {
      return '2 ngày nữa';
    } else if (daysRemaining > 2) {
      return 'Còn $daysRemaining ngày nữa';
    } else if (daysRemaining == -1) {
      return 'Hôm qua';
    } else if (daysRemaining == -2) {
      return '2 ngày trước';
    } else {
      return 'Đã qua ${daysRemaining.abs()} ngày';
    }
  }

  // Hiển thị lỗi
  void showError(String message) {
    SnackbarUtils.showError(message);
  }

  // Lấy tên category bằng ID
  String getCategoryNameById(String categoryId) {
    final category =
        eventCategories.firstWhereOrNull((cat) => cat.id == categoryId);
    return category?.title ?? 'Không xác định';
  }

  // Xóa sự kiện
  Future<void> deleteEvent(String eventId) async {
    try {
      final eventExists = eventServices.getEventById(eventId) != null;
      if (!eventExists) {
        LoggerUtils.warning('Attempted to delete non-existent event: $eventId');
        showError('Sự kiện không tồn tại hoặc đã bị xóa.');
        return;
      }

      final result = await eventServices.deleteEvent(eventId);
      if (result) {
        events.removeWhere((event) => event.id == eventId);
        _filterEvents();

        SnackbarUtils.showSuccess('Đã xóa sự kiện thành công');
      } else {
        showError('Không thể xóa sự kiện. Vui lòng thử lại sau.');
      }
    } catch (e) {
      LoggerUtils.error('Error deleting event', e);
      showError('Có lỗi xảy ra khi xóa sự kiện.');
    }
  }

  // Cập nhật sự kiện
  Future<void> updateEvent(Event updatedEvent) async {
    try {
      _startLoading();
      final result = await eventServices.updateEvent(updatedEvent);

      if (result) {
        final index = events.indexWhere((e) => e.id == updatedEvent.id);
        if (index >= 0) {
          events[index] = updatedEvent;
        }
        _filterEvents();

        SnackbarUtils.showSuccess('Đã cập nhật sự kiện thành công');
      } else {
        showError('Không thể cập nhật sự kiện. Vui lòng thử lại sau.');
      }
    } catch (e) {
      LoggerUtils.error('Error updating event', e);
      showError('Có lỗi xảy ra khi cập nhật sự kiện.');
    } finally {
      _stopLoading();
    }
  }

  List<String> getRepeatOptions() {
    return [
      "Không lặp lại",
      "Hằng ngày",
      "Hằng tuần",
      "Hằng tháng",
      "Hằng năm",
    ];
  }

  String mapRepeatTypeToApi(String vietnameseType) {
    switch (vietnameseType) {
      case "Hằng ngày":
        return "daily";
      case "Hằng tuần":
        return "weekly";
      case "Hằng tháng":
        return "monthly";
      case "Hằng năm":
        return "yearly";
      default:
        return "none";
    }
  }

  String mapRepeatTypeFromApi(String apiType) {
    switch (apiType) {
      case "daily":
        return "Hằng ngày";
      case "weekly":
        return "Hằng tuần";
      case "monthly":
        return "Hằng tháng";
      case "yearly":
        return "Hằng năm";
      default:
        return "Không lặp lại";
    }
  }

  String getVietnameseWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return "Thứ 2";
      case 2:
        return "Thứ 3";
      case 3:
        return "Thứ 4";
      case 4:
        return "Thứ 5";
      case 5:
        return "Thứ 6";
      case 6:
        return "Thứ 7";
      case 7:
        return "Chủ nhật";
      default:
        return "";
    }
  }

  void showDeleteConfirmation(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Xác nhận xóa",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Bạn có chắc chắn muốn xóa sự kiện '${event.title}' không?",
            style: TextStyle(fontSize: 18.sp),
          ),
          actions: [
            TextButton(
              child: Text(
                "Hủy",
                style: TextStyle(color: Colors.grey, fontSize: 18.sp),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "Xóa",
                style: TextStyle(color: Colors.red, fontSize: 18.sp),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                deleteEvent(event.id);
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  void navigateToEditEvent(Event event) {
    Get.toNamed(
      Routes.CREATE_NEW_EVENT,
      arguments: {'event': event, 'isEdit': true},
    )?.then((result) {
      if (result == true) {
        loadEvents();
      }
    });
  }

  List<Map<String, dynamic>> getFormattedEvents() {
    return filteredEvents.map((event) {
      final DateTime eventDate = event.eventDate;
      // final String formattedDate = DateFormat('dd/MM/yyyy').format(eventDate); // Không cần nữa cho 'dateTime'
      final String formattedTime = event.eventTime; // This is "HH:mm"
      final String remainingDays = calculateRemainingDays(eventDate);

      IconData eventIcon;
      switch (event.repeatType) {
        case 'daily':
          eventIcon = Icons.repeat_one;
          break;
        case 'weekly':
          eventIcon = Icons.view_week;
          break;
        case 'monthly':
          eventIcon = Icons.calendar_view_month;
          break;
        case 'yearly':
          eventIcon = Icons.calendar_today;
          break;
        default:
          eventIcon = Icons.event_outlined;
      }

      String categoryName;
      if (event.categoryId != null && event.categoryId!.isNotEmpty) {
        categoryName = getCategoryNameById(event.categoryId!);
      } else {
        categoryName = 'Chưa phân loại';
      }

      return {
        'event': event,
        // ---- FIX: Pass only the time string to 'dateTime' ----
        'dateTime': formattedTime,
        // ------------------------------------------------------
        'remaining': remainingDays,
        'description': event.description,
        'eventIcon': eventIcon,
        'isNotify': event.isNotify,
        'categoryName': categoryName,
        // Pass the solar date string separately
        'solarDateString': app_date_utils.DateTimeUtils.formatDMY(eventDate),
      };
    }).toList();
  }
}
