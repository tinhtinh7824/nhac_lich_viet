import 'package:get/get.dart';
import '../modules/events/views/events_view.dart';
import '../modules/events/bindings/events_binding.dart';
import '../modules/add_event/views/add_event_view.dart';
import '../modules/add_event/bindings/add_event_binding.dart';
import '../modules/event_countdown/views/event_countdown_view.dart';
import '../modules/event_countdown/bindings/event_countdown_binding.dart';
import '../modules/event_search/views/event_search_view.dart';
import '../modules/event_search/bindings/event_search_binding.dart';
import '../modules/profile_event/views/profile_event_view.dart';
import '../modules/profile_event/bindings/profile_event_binding.dart';
import '../modules/daily_event_popup/views/daily_event_popup_view.dart';
import '../modules/daily_event_popup/bindings/daily_event_popup_binding.dart';
import '../modules/add_event/views/create_new_event_view.dart';
import '../modules/ai_chat/views/ai_chat_view.dart';
import '../modules/ai_chat/bindings/ai_chat_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.EVENTS;

  static final routes = [
    GetPage(
      name: _Paths.EVENTS,
      page: () => const EventsView(),
      binding: EventsBinding(),
    ),
    GetPage(
      name: _Paths.ADD_EVENT,
      page: () => const AddEventView(),
      binding: AddEventBinding(),
    ),
    GetPage(
      name: _Paths.EVENT_COUNTDOWN,
      page: () => const EventCountdownView(),
      binding: EventCountdownBinding(),
    ),
    GetPage(
      name: _Paths.EVENT_SEARCH,
      page: () => const EventSearchView(),
      binding: EventSearchBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE_EVENT,
      page: () => const ProfileEventView(),
      binding: ProfileEventBinding(),
    ),
    GetPage(
      name: _Paths.DAILY_EVENT_POPUP,
      page: () => DailyEventPopupView(event: Get.arguments['event']),
      binding: DailyEventPopupBinding(),
    ),
    GetPage(
      name: _Paths.CREATE_NEW_EVENT,
      page: () => const CreateEventView(),
      binding: AddEventBinding(),
    ),
    GetPage(
      name: _Paths.AI_CHAT,
      page: () => const AiChatView(),
      binding: AiChatBinding(),
    ),
  ];
}
