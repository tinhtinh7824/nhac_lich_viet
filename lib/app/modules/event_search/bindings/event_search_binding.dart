// File: app/modules/events/bindings/event_search_binding.dart
import 'package:get/get.dart';
import '../controllers/event_search_controller.dart'; // Sẽ tạo controller này

class EventSearchBinding extends Bindings {
  @override
  void dependencies() {
    // Đảm bảo EventServices đã được đăng ký (thường là ở AppBinding hoặc MainHomeBinding)
    // Get.lazyPut<EventServices>(() => EventServices()); // Chỉ bật nếu chưa đăng ký ở nơi khác

    Get.lazyPut<EventSearchController>(
      () => EventSearchController(),
    );
  }
}
