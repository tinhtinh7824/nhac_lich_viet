import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/event_category_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/custom_reminder_config.dart';
import '../../../services/event_category_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/logger_utils.dart';
import '../../../routes/app_pages.dart';
import '../../../services/analytics_service.dart';

class AddEventController extends GetxController {
  final EventCategoryService _service = Get.find<EventCategoryService>();

  final categories = <EventCategory>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedDate = DateTime.now().obs; // Thêm selectedDate

  @override
  void onInit() {
    super.onInit();

    // Track dialog shown
    try {
      Get.find<AnalyticsService>().logDialogShown(
        'add_event_dialog',
        parameters: {'context': 'event_management'},
      );
    } catch (e) {
      LoggerUtils.debug('Analytics tracking failed: $e');
    }

    // Kiểm tra và lấy ngày được chọn từ tham số (nếu có)
    if (Get.arguments != null && Get.arguments['selectedDate'] != null) {
      selectedDate.value = Get.arguments['selectedDate'];
    }

    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1. Lấy dữ liệu từ cache trước
      final cachedCategories = await _service.getCachedCategories();
      LoggerUtils.debug('Cached categories: ${cachedCategories.length}');

      // 2. Nếu có dữ liệu cache, hiển thị ngay
      if (cachedCategories.isNotEmpty) {
        // Filter out system events category
        final filteredCachedCategories = cachedCategories
            .where((category) => category.title != 'Sự kiện hệ thống')
            .toList();
        categories.value = filteredCachedCategories;
        isLoading.value = false;
      }

      // 3. Gọi API để cập nhật dữ liệu mới
      final newCategories = await _service.fetchCategories();
      LoggerUtils.debug('New categories from API: ${newCategories.length}');

      // 4. Nếu API thành công, cập nhật cache và UI
      if (newCategories.isNotEmpty) {
        await _service.cacheCategories(newCategories);
        // Filter out system events category
        final filteredNewCategories = newCategories
            .where((category) => category.title != 'Sự kiện hệ thống')
            .toList();
        categories.value = filteredNewCategories;
      } else if (categories.isEmpty) {
        errorMessage.value = 'Không có dữ liệu danh mục sự kiện';
      }
    } catch (e) {
      LoggerUtils.error('Error loading categories', e);
      errorMessage.value = 'Có lỗi xảy ra khi tải dữ liệu';
    } finally {
      isLoading.value = false;
    }
  }

  // Phương thức để chuyển đến trang tạo sự kiện với category đã chọn
  void navigateToCreateEvent(EventCategory category) {
    Get.toNamed(Routes.CREATE_NEW_EVENT, arguments: {
      'category': category,
      'selectedDate': selectedDate.value,
    });
  }

  
  
}
