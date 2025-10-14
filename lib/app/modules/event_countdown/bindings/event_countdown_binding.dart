import 'package:get/get.dart';
import '../controllers/event_countdown_controller.dart';

class EventCountdownBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EventCountdownController>(
      () => EventCountdownController(),
    );
  }
}