import 'package:nhac_lich_viet/app/data/providers/api_provider.dart';
import 'package:nhac_lich_viet/app/data/providers/database_provider.dart';
import 'package:nhac_lich_viet/app/data/providers/storage_provider.dart';
import 'package:nhac_lich_viet/app/modules/events/controllers/events_controller.dart';
import 'package:nhac_lich_viet/app/services/api_refresh_service.dart';
import 'package:nhac_lich_viet/app/services/event_category_service.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/services/notification_service.dart';
import 'package:nhac_lich_viet/app/utils/network_utils.dart';
import 'package:get/get.dart';

/// Dependency Injection binding cho Events Module
/// Đây là initial binding của app, chịu trách nhiệm khởi tạo tất cả global services
class EventsBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Initialize NetworkUtils (static utility) - fire and forget
    // Chạy async nhưng không block initialization
    NetworkUtils.init();

    // 2. Register core providers (QUAN TRỌNG - phải đăng ký TRƯỚC services)
    if (!Get.isRegistered<DatabaseProvider>()) {
      Get.put(DatabaseProvider(), permanent: true);
    }

    if (!Get.isRegistered<ApiProvider>()) {
      Get.put(ApiProvider(), permanent: true);
    }

    if (!Get.isRegistered<StorageProvider>()) {
      Get.put(StorageProvider(), permanent: true);
    }

    // 3. Register global services (permanent: true để tồn tại suốt lifecycle app)
    // QUAN TRỌNG: NotificationService phải đăng ký TRƯỚC EventServices
    if (!Get.isRegistered<NotificationService>()) {
      Get.put(NotificationService(), permanent: true);
    }

    if (!Get.isRegistered<EventCategoryService>()) {
      Get.put(EventCategoryService(), permanent: true);
    }

    if (!Get.isRegistered<EventServices>()) {
      final eventServices = Get.put(EventServices(), permanent: true);
      // Initialize EventServices AFTER a short delay to ensure providers are ready
      // This prevents race condition with DatabaseProvider.onInit()
      Future.delayed(const Duration(milliseconds: 100), () {
        eventServices.init();
      });
    }

    // 4. Register ApiRefreshService (cần thiết cho EventsController)
    // Service này phụ thuộc vào NetworkUtils nhưng có error handling
    if (!Get.isRegistered<ApiRefreshService>()) {
      Get.put(ApiRefreshService(), permanent: true);
    }

    // 5. Register EventsController (lazy loading - chỉ tạo khi cần)
    Get.lazyPut<EventsController>(
      () => EventsController(),
    );
  }
}
