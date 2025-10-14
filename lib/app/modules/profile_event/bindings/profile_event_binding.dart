import 'package:nhac_lich_viet/app/modules/profile_event/controllers/profile_event_controller.dart';
import 'package:get/get.dart';

class ProfileEventBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileEventController>(
      () => ProfileEventController(),
    );
  }
}
