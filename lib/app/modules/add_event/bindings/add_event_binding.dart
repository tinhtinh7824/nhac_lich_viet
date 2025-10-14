import 'package:nhac_lich_viet/app/modules/add_event/controllers/notification_settings_controller.dart';
import 'package:nhac_lich_viet/app/data/providers/api_provider.dart';
import 'package:nhac_lich_viet/app/data/providers/database_provider.dart';
import 'package:nhac_lich_viet/app/data/providers/storage_provider.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/services/notification_service.dart';
import 'package:get/get.dart';
import '../controllers/add_event_controller.dart';
import '../controllers/create_event_controller.dart';
import '../../../services/event_category_service.dart';

class AddEventBinding extends Bindings {
  @override
  void dependencies() {
    // Đảm bảo các provider cơ bản đã được đăng ký (nếu chưa có)
    if (!Get.isRegistered<DatabaseProvider>()) {
      Get.put(DatabaseProvider(), permanent: true);
    }

    if (!Get.isRegistered<ApiProvider>()) {
      Get.put(ApiProvider(), permanent: true);
    }

    if (!Get.isRegistered<StorageProvider>()) {
      Get.put(StorageProvider(), permanent: true);
    }

    // Đảm bảo NotificationService đã được đăng ký (cần thiết cho EventServices)
    if (!Get.isRegistered<NotificationService>()) {
      Get.put(NotificationService(), permanent: true);
    }

    // Đảm bảo EventServices đã được đăng ký (cần thiết cho CreateEventController)
    if (!Get.isRegistered<EventServices>()) {
      final eventServices = Get.put(EventServices(), permanent: true);
      // Initialize EventServices nếu chưa được khởi tạo
      Future.delayed(const Duration(milliseconds: 100), () {
        eventServices.init();
      });
    }

    // Đảm bảo EventCategoryService đã được đăng ký
    if (!Get.isRegistered<EventCategoryService>()) {
      Get.put(EventCategoryService(), permanent: true);
    }

    // Controller cho trang danh sách danh mục - đăng ký trước
    Get.put<AddEventController>(AddEventController());

    // Controller cho trang tạo sự kiện - đăng ký sau AddEventController
    Get.lazyPut<CreateEventController>(() => CreateEventController());
    Get.lazyPut<NotificationSettingsController>(
        () => NotificationSettingsController());
  }
}
