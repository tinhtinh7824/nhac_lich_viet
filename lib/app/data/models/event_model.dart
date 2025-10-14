import 'package:nhac_lich_viet/app/utils/lunar_utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:equatable/equatable.dart';
import 'custom_reminder_config.dart';
part 'event_model.g.dart';

// Enum để quản lý các loại sự kiện
enum EventTypeEnum {
  system_event('system_event'),
  user_event('user_event'),
  system_notification('system_notification'),
  user_action('user_action'),
  error('error'),
  warning('warning'),
  info('info'),
  custom('custom');

  final String value;
  const EventTypeEnum(this.value);
}

// Enum để quản lý mức độ nghiêm trọng của sự kiện
enum EventSeverityEnum { critical, high, medium, low }

// Enum cho loại lặp lại
enum EventRepeatTypeEnum { none, daily, weekly, monthly, yearly, custom }

// Enum cho kênh thông báo
enum NotificationChannelEnum { email, in_app, push, sms }

// Enum cho trạng thái gửi
enum DeliveryStatusEnum { scheduled, sent, failed, pending, cancelled }

// --- SimpleNotificationConfig Model ---
@HiveType(typeId: 1) // Gán một typeId duy nhất (ví dụ: 1)
class SimpleNotificationConfig extends HiveObject with EquatableMixin {
  @HiveField(0)
  final bool notifyOnDay;
  @HiveField(1)
  final List<int> notifyDaysBefore; // Lưu trữ bằng phút (API trả về ngày, tự động quy đổi)
  @HiveField(2)
  final String notifyTime; // Giữ dạng String "HH:mm"

  SimpleNotificationConfig({
    this.notifyOnDay = true,
    this.notifyDaysBefore = const [],
    this.notifyTime = "06:30",
  });
  SimpleNotificationConfig copyWith({
    bool? notifyOnDay,
    List<int>? notifyDaysBefore,
    String? notifyTime,
  }) {
    return SimpleNotificationConfig(
      notifyOnDay: notifyOnDay ?? this.notifyOnDay,
      notifyDaysBefore: notifyDaysBefore ?? this.notifyDaysBefore,
      notifyTime: notifyTime ?? this.notifyTime,
    );
  }

  factory SimpleNotificationConfig.fromJson(Map<String, dynamic>? json, {bool isFromAPI = true}) {
    if (json == null) {
      // Trả về giá trị mặc định nếu json là null
      return SimpleNotificationConfig();
    }
    
    List<int> notifyDaysBeforeInMinutes = [];
    if (json['notifyDaysBefore'] != null && json['notifyDaysBefore'] is List) {
      if (isFromAPI) {
        // Từ API: quy đổi ngày sang phút (1 ngày = 1440 phút)
        notifyDaysBeforeInMinutes = (json['notifyDaysBefore'] as List)
            .map((day) => (day as int) * 1440)
            .toList();
      } else {
        // Từ local storage: đã là phút rồi, giữ nguyên
        notifyDaysBeforeInMinutes = (json['notifyDaysBefore'] as List)
            .map((minutes) => minutes as int)
            .toList();
      }
    }
    
    return SimpleNotificationConfig(
      notifyOnDay: json['notifyOnDay'] ?? true,
      notifyDaysBefore: notifyDaysBeforeInMinutes,
      notifyTime: json['notifyTime'] ?? "06:30",
    );
  }

  Map<String, dynamic> toJson() {
    // KHÔNG quy đổi - giữ nguyên giá trị phút
    // API backend sẽ tự xử lý nếu cần
    return {
      'notifyOnDay': notifyOnDay,
      'notifyDaysBefore': notifyDaysBefore, // Giữ nguyên phút
      'notifyTime': notifyTime,
    };
  }

  @override
  List<Object?> get props => [notifyOnDay, notifyDaysBefore, notifyTime];
}

// --- Event Model ---
@HiveType(typeId: 0) // Gán một typeId duy nhất (ví dụ: 0)
class Event extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id; // Dùng làm key trong Hive

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? subtitle; // Giữ lại nếu cần

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String? detail; // Giữ lại nếu cần

  @HiveField(5)
  final String eventType;

  @HiveField(6)
  final bool isNotify; // Cài đặt bật/tắt thông báo chung (user có thể đổi)

  @HiveField(7)
  final DateTime eventDate; // Lưu DateTime để dễ query/sort

  @HiveField(8)
  final String eventTime; // Giữ dạng "HH:mm"

  @HiveField(9)
  final String repeatType; // none, daily, weekly, monthly, yearly

  @HiveField(10)
  final String? iconUrl;

  @HiveField(11)
  final String? bannerUrl;

  @HiveField(12)
  final String? wishes;

  @HiveField(13)
  final bool showOnCalendar;

  @HiveField(14)
  final bool showNotificationOnOpen;

  @HiveField(15)
  final String? categoryId;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  @HiveField(18)
  final SimpleNotificationConfig? simpleNotificationConfig; // Trường mới

  @HiveField(19)
  final String? originalEventId; // ID của sự kiện gốc nếu đây là occurrence

  @HiveField(20)
  final bool isOccurrence; // Đánh dấu nếu đây là occurrence đã tính toán

  @HiveField(21)
  final List<CustomReminderConfig>? customReminders;

  @HiveField(22) // Thêm một field mới
  final bool isLunar; // Đánh dấu sự kiện có nguồn gốc âm lịch

  @HiveField(23) // Tùy chọn: lưu trữ ngày âm lịch gốc
  final DateTime? originalLunarDate;
  Event({
    required this.id,
    required this.title,
    this.subtitle,
    required this.description,
    this.detail,
    required this.eventType,
    required this.isNotify,
    required this.eventDate,
    required this.eventTime,
    required this.repeatType,
    this.iconUrl,
    this.bannerUrl,
    this.wishes,
    required this.showOnCalendar,
    required this.showNotificationOnOpen,
    this.categoryId,
    this.simpleNotificationConfig,
    required this.createdAt,
    required this.updatedAt,
    this.originalEventId,
    this.isOccurrence = false,
    this.customReminders,
    required this.isLunar,
    this.originalLunarDate,
  });

  // Bỏ: severity, targetUsers, isRead, advancedNotificationConfig
  // Thêm: simpleNotificationConfig, originalEventId, isOccurrence

  Event copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? detail,
    String? eventType,
    bool? isNotify,
    DateTime? eventDate,
    String? eventTime,
    String? repeatType,
    String? iconUrl,
    String? bannerUrl,
    String? wishes,
    bool? showOnCalendar,
    bool? showNotificationOnOpen,
    String? categoryId,
    SimpleNotificationConfig? simpleNotificationConfig,
    String? originalEventId,
    bool? isOccurrence,
    List<CustomReminderConfig>? customReminders, // <<< THÊM VÀO COPYWITH
    DateTime?
        createdAt, // Cho phép copy createdAt để giữ nguyên khi tạo occurrence
    DateTime? updatedAt,
    bool? isLunar, // Thêm trường mới
    DateTime? originalLunarDate, // Thêm trường mới
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      detail: detail ?? this.detail,
      eventType: eventType ?? this.eventType,
      isNotify: isNotify ?? this.isNotify,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      repeatType: repeatType ?? this.repeatType,
      iconUrl: iconUrl ?? this.iconUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      wishes: wishes ?? this.wishes,
      showOnCalendar: showOnCalendar ?? this.showOnCalendar,
      showNotificationOnOpen:
          showNotificationOnOpen ?? this.showNotificationOnOpen,
      categoryId: categoryId ?? this.categoryId,
      simpleNotificationConfig:
          simpleNotificationConfig ?? this.simpleNotificationConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      originalEventId: originalEventId ?? this.originalEventId,
      isOccurrence: isOccurrence ?? this.isOccurrence,
      customReminders:
          customReminders ?? this.customReminders, // <<< THÊM VÀO COPYWITH
      isLunar: isLunar ?? this.isLunar, // Thêm trường mới
      originalLunarDate:
          originalLunarDate ?? this.originalLunarDate, // Thêm trường mới
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    // Helper function để parse list custom reminders
    List<CustomReminderConfig>? parseCustomReminders(dynamic list) {
      if (list == null || list is! List) return null;
      try {
        return list
            .map((item) =>
                CustomReminderConfig.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } catch (e) {
        print("Error parsing custom reminders: $e");
        return null;
      }
    }

    DateTime eventDateDateTime;
    DateTime? originalLunarDate;
    bool isLunar = json['isLunar'] == true;

    if (isLunar && json['eventDate'] != null) {
      originalLunarDate = DateTime.parse(json['eventDate']);
      eventDateDateTime = LunarUtils.convertLunarToSolar(originalLunarDate);
    } else if (json['eventDate'] != null) {
      eventDateDateTime = DateTime.parse(json['eventDate']);
    } else {
      eventDateDateTime = DateTime.now();
    }
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      description: json['description'] ?? '',
      detail: json['detail'],
      eventType: json['eventType'] ?? 'system_event',
      isNotify: json['isNotify'] ?? false,
      eventDate: eventDateDateTime,
      eventTime: json['eventTime'] ?? '00:00',
      repeatType:
          json['repeatType'] ?? 'Không lặp lại', // Mặc định là không lặp
      iconUrl: json['iconUrl'],
      bannerUrl: json['bannerUrl'],
      wishes: json['wishes'],
      showOnCalendar: json['showOnCalendar'] ?? true,
      showNotificationOnOpen: json['showNotificationOnOpen'] ?? false,
      categoryId: json['categoryId'],
      simpleNotificationConfig: json['simpleNotificationConfig'] != null
          ? SimpleNotificationConfig.fromJson(json['simpleNotificationConfig'])
          : null, // Xử lý null
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      originalEventId: json['originalEventId'],
      isOccurrence: json['isOccurrence'] ?? false,
      customReminders:
          parseCustomReminders(json['customReminders']), // <<< THÊM PARSE
      isLunar: isLunar,
      originalLunarDate: originalLunarDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'detail': detail,
      'eventType': eventType,
      'isNotify': isNotify,
      'eventDate': eventDate.toIso8601String(),
      'eventTime': eventTime,
      'repeatType': repeatType,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
      'wishes': wishes,
      'showOnCalendar': showOnCalendar,
      'showNotificationOnOpen': showNotificationOnOpen,
      'categoryId': categoryId,
      'simpleNotificationConfig': simpleNotificationConfig?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'originalEventId': originalEventId,
      'isOccurrence': isOccurrence,
      'customReminders': customReminders?.map((e) => e.toJson()).toList(),
      'isLunar': isLunar,
      'originalLunarDate': originalLunarDate?.toIso8601String(),
    };
  }

  // --- Extensions hữu ích ---
  Color getSeverityColor() {
    // Bỏ logic cũ vì trường severity đã bị loại bỏ
    return Colors.blue; // Hoặc màu mặc định khác
  }

  IconData getTypeIcon() {
    switch (eventType) {
      case 'system_event':
        return Icons.event;
      case 'user_event':
        return Icons.person_outline;
      // Bỏ các case không còn dùng
      default:
        return Icons.event_note;
    }
  }

  String getFormattedDate() {
    return DateFormat('dd/MM/yyyy').format(eventDate);
  }

  String getTypeLabel() {
    switch (eventType) {
      case 'system_event':
        return 'Sự kiện hệ thống';
      case 'user_event':
        return 'Sự kiện người dùng';
      // Bỏ các case không còn dùng
      default:
        return 'Không xác định';
    }
  }

  // Triển khai Equatable để so sánh
  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        description,
        detail,
        eventType,
        isNotify,
        eventDate,
        eventTime,
        repeatType,
        iconUrl,
        bannerUrl,
        wishes,
        showOnCalendar,
        showNotificationOnOpen,
        categoryId,
        simpleNotificationConfig,
        createdAt,
        updatedAt,
        originalEventId,
        isOccurrence,
        customReminders, // <<< THÊM VÀO PROPS
      ];
}

// --- EventResponse Model ---
// Giữ nguyên nếu backend vẫn trả về cấu trúc này
class EventResponse {
  final bool success;
  final String message;
  final EventResponseObject responseObject;
  final int statusCode;

  EventResponse({
    required this.success,
    required this.message,
    required this.responseObject,
    required this.statusCode,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      responseObject:
          EventResponseObject.fromJson(json['responseObject'] ?? {}),
      statusCode: json['statusCode'] ?? 400,
    );
  }
}

class EventResponseObject {
  final List<Event> events;
  final int total;

  EventResponseObject({
    required this.events,
    required this.total,
  });

  factory EventResponseObject.fromJson(Map<String, dynamic> json) {
    return EventResponseObject(
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => Event.fromJson(e))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}
