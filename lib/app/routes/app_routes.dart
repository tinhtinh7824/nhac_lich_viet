part of 'app_pages.dart';

abstract class Routes {
  Routes._();

  static const HOME = _Paths.HOME;
  static const EVENTS = _Paths.EVENTS;
  static const ADD_EVENT = _Paths.ADD_EVENT;
  static const EVENT_DETAIL = _Paths.EVENT_DETAIL;
  static const EVENT_COUNTDOWN = _Paths.EVENT_COUNTDOWN;
  static const EVENT_SEARCH = _Paths.EVENT_SEARCH;
  static const PROFILE_EVENT = _Paths.PROFILE_EVENT;
  static const DAILY_EVENT_POPUP = _Paths.DAILY_EVENT_POPUP;
  static const CREATE_NEW_EVENT = _Paths.CREATE_NEW_EVENT;
  static const AI_CHAT = _Paths.AI_CHAT;
}

abstract class _Paths {
  _Paths._();

  static const HOME = '/home';
  static const EVENTS = '/events';
  static const ADD_EVENT = '/add-event';
  static const EVENT_DETAIL = '/event-detail';
  static const EVENT_COUNTDOWN = '/event-countdown';
  static const EVENT_SEARCH = '/event-search';
  static const PROFILE_EVENT = '/profile-event';
  static const DAILY_EVENT_POPUP = '/daily-event-popup';
  static const CREATE_NEW_EVENT = '/create-new-event';
  static const AI_CHAT = '/ai-chat';
}
