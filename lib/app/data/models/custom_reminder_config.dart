// File: app/data/models/custom_reminder_config.dart
import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart'; // Cần cho định dạng ngày

part 'custom_reminder_config.g.dart'; // Sẽ được tạo bởi build_runner

enum CustomReminderType { countdown, specificDate }

@HiveType(typeId: 2) // *** CHỌN typeId KHÁC (vd: 2) ***
// ignore: must_be_immutable
class CustomReminderConfig extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id; // ID duy nhất cho mỗi custom reminder

  @HiveField(1)
  final CustomReminderType type;

  // Dùng cho countdown
  @HiveField(2)
  final int? countdownHours;
  @HiveField(3)
  final int? countdownMinutes;

  // Dùng cho specificDate
  @HiveField(4)
  final DateTime? specificDateTime; // Lưu cả ngày và giờ

  CustomReminderConfig({
    required this.id,
    required this.type,
    this.countdownHours,
    this.countdownMinutes,
    this.specificDateTime,
  });

  factory CustomReminderConfig.fromJson(Map<String, dynamic> json) {
    return CustomReminderConfig(
      id: json['id'] ?? '', // Cần id để xác định
      type: json['type'] == 'specificDate'
          ? CustomReminderType.specificDate
          : CustomReminderType.countdown,
      countdownHours: json['countdownHours'],
      countdownMinutes: json['countdownMinutes'],
      specificDateTime: json['specificDateTime'] != null
          ? DateTime.parse(json['specificDateTime'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == CustomReminderType.specificDate
          ? 'specificDate'
          : 'countdown',
      'countdownHours': countdownHours,
      'countdownMinutes': countdownMinutes,
      'specificDateTime': specificDateTime?.toIso8601String(),
    };
  }

  // Helper để hiển thị text trên UI (trong NotificationSettingsDialog)
  String getDisplayText() {
    if (type == CustomReminderType.countdown) {
      final hours = countdownHours ?? 0;
      final minutes = countdownMinutes ?? 0;
      if (hours > 0 && minutes > 0) {
        return "Nhắc trước $hours giờ $minutes phút";
      } else if (hours > 0) {
        return "Nhắc trước $hours giờ";
      } else if (minutes > 0) {
        return "Nhắc trước $minutes phút";
      } else {
        return "Nhắc trước (không xác định)";
      }
    } else if (type == CustomReminderType.specificDate &&
        specificDateTime != null) {
      final DateFormat formatter = DateFormat('HH:mm dd/MM/yyyy');
      return "Nhắc lúc ${formatter.format(specificDateTime!)}";
    }
    return "Nhắc tùy chỉnh (lỗi)";
  }

  @override
  List<Object?> get props =>
      [id, type, countdownHours, countdownMinutes, specificDateTime];
}
