// File: app/modules/events/controllers/event_search_controller.dart
import 'dart:async';
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/modules/events/controllers/events_controller.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EventSearchController extends GetxController {
  final EventServices _eventServices = Get.find<EventServices>();
  final EventsController _eventsController = Get.find<EventsController>();

  // --- State Variables ---
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final RxString searchQuery = ''.obs;
  final RxString lastSearchedQuery = ''.obs; // Track last searched query
  final RxBool isLoading = false.obs;
  final RxBool hasResults = false.obs;
  final RxBool isDebouncing = false.obs; // Track debounce state
  final RxList<Event> searchResults = <Event>[].obs;
  final RxBool hasAttemptedSearch = false.obs;

  Timer? _debounce;
  final Duration debounceDuration =
      const Duration(milliseconds: 400); // Thời gian chờ debounce

  @override
  void onInit() {
    super.onInit();
    // Tự động focus vào ô tìm kiếm khi màn hình mở
    searchFocusNode.requestFocus();
    // Lắng nghe thay đổi trong ô tìm kiếm
    searchController.addListener(_onSearchChanged);
    // Lắng nghe thay đổi của searchQuery để thực hiện tìm kiếm
    debounce(searchQuery, performSearch, time: debounceDuration);
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  // Cập nhật searchQuery khi text thay đổi
  void _onSearchChanged() {
    searchQuery.value = searchController.text;
    
    // Set debouncing state if query changed
    if (searchQuery.value != lastSearchedQuery.value && searchQuery.value.isNotEmpty) {
      isDebouncing.value = true;
    }
  }

  // Thực hiện tìm kiếm (được gọi bởi debounce)
  Future<void> performSearch(String query) async {
    final trimmedQuery = query.trim();
    
    // Update search state
    isDebouncing.value = false;
    lastSearchedQuery.value = query;
    hasAttemptedSearch.value = false;
    
    if (trimmedQuery.isEmpty) {
      searchResults.clear();
      hasResults.value = false;
      isLoading.value = false; // Đảm bảo tắt loading khi query rỗng
      return;
    }

    isLoading.value = true;
    hasResults.value = false; // Reset trạng thái kết quả

    try {
      // Gọi service để lấy danh sách sự kiện đã lọc theo keyword
      final filteredEvents = await _eventServices.searchEventsByKeyword(
        trimmedQuery,
        candidateEvents: _collectEventsFromAllTab(),
      );

      // Sắp xếp kết quả theo logic yêu cầu
      final sortedEvents = _sortEvents(filteredEvents);

      searchResults.value = sortedEvents;
      hasResults.value = sortedEvents.isNotEmpty;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error performing event search', e, stackTrace);
      searchResults.clear();
      hasResults.value = false;
      // Có thể hiển thị lỗi cho người dùng nếu cần
      SnackbarUtils.showError('Không thể tìm kiếm sự kiện.');
    } finally {
      isLoading.value = false;
      hasAttemptedSearch.value = true;
    }
  }

  // Logic sắp xếp sự kiện đặc biệt
  List<Event> _sortEvents(List<Event> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcomingOrToday = <Event>[];
    final past = <Event>[];

    for (final event in events) {
      final eventDate = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);
      if (eventDate.isAfter(today) || eventDate.isAtSameMomentAs(today)) {
        upcomingOrToday.add(event);
      } else {
        past.add(event);
      }
    }

    // Sắp xếp các sự kiện sắp tới/hôm nay theo thứ tự thời gian tăng dần
    upcomingOrToday.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    // Sắp xếp các sự kiện đã qua theo thứ tự thời gian tăng dần
    past.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    // Ghép danh sách: sắp tới/hôm nay trước, sau đó đến đã qua
    return [...upcomingOrToday, ...past];
  }

  // Xóa nội dung tìm kiếm
  void clearSearch() {
    searchController.clear();
    // searchQuery.value = ''; // Không cần vì listener đã xử lý
    searchResults.clear();
    hasResults.value = false;
    isDebouncing.value = false;
    lastSearchedQuery.value = '';
    searchFocusNode.requestFocus(); // Focus lại vào ô tìm kiếm
  }

  // Quay lại màn hình trước (Hủy)
  void cancelSearch() {
    Get.back();
  }

  List<Event> _collectEventsFromAllTab() {
    final List<Event> combined = [];
    final Set<String> seenIds = {};

    void addEvents(Iterable<Event> events) {
      for (final event in events) {
        final id = event.id;
        if (seenIds.add(id)) {
          combined.add(event);
        }
      }
    }

    addEvents(_eventsController.allTodayEvents);
    addEvents(_eventsController.allUpcomingEvents);
    addEvents(_eventsController.allPastEvents);

    if (combined.isEmpty) {
      addEvents(_eventsController.todayEvents);
      addEvents(_eventsController.upcomingEvents);
      addEvents(_eventsController.pastEvents);
    }

    if (combined.length > 400) {
      return combined.take(400).toList();
    }
    return combined;
  }
}
