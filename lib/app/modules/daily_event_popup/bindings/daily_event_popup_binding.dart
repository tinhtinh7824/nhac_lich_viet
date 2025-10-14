import 'package:get/get.dart';
import '../controllers/daily_event_popup_controller.dart';
// Không cần import EventServices và StorageProvider ở đây nữa vì controller sẽ tự Get.find()

class DailyEventPopupBinding extends Bindings {
  @override
  void dependencies() {
    // Khởi tạo DailyEventPopupController
    // Sử dụng Get.put thay vì lazyPut và fenix: true để đảm bảo controller
    // được khởi tạo ngay và tồn tại xuyên suốt sau khi được put lần đầu.
    // Điều này quan trọng vì logic check popup cần chạy sớm.
    Get.put<DailyEventPopupController>(
      DailyEventPopupController(),
      permanent: true, // Đảm bảo controller này không bị hủy tự động
    );
  }
}
