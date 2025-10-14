// File: app/modules/add_event/controllers/notification_settings_controller.dart
import 'package:nhac_lich_viet/app/data/models/custom_reminder_config.dart'; // <<< THÊM IMPORT
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationSettingsController extends GetxController {

  // Reactive state for default options
  final RxMap<String, bool> currentNotifyOptions = <String, bool>{}.obs;
  final Rx<TimeOfDay> selectedNotifyTime =
      const TimeOfDay(hour: 8, minute: 0).obs;

  // *** THÊM STATE CHO CUSTOM REMINDERS ***
  final RxList<CustomReminderConfig> currentCustomReminders =
      <CustomReminderConfig>[].obs;
  final RxMap<String, bool> customReminderStates =
      <String, bool>{}.obs; // Key: CustomReminderConfig.id
  // ----------------------------------------

  // Fixed list of default notification options
  final List<MapEntry<String, int?>> displayOptions = [
    MapEntry("Nhắc khi bắt đầu sự kiện", 0),
    MapEntry("Nhắc trước 5 phút", 5),
    MapEntry("Nhắc trước 15 phút", 15),
    MapEntry("Nhắc trước 30 phút", 30),
    MapEntry("Nhắc trước 1 giờ", 60),
    MapEntry("Nhắc trước 2 giờ", 120),
    MapEntry("Nhắc trước 1 ngày", 1440),
    MapEntry("Nhắc trước 2 ngày", 2880),
    MapEntry("Nhắc trước 3 ngày", 4320),
    MapEntry("Nhắc trước 5 ngày", 7200),
    MapEntry("Nhắc trước 1 tuần", 10080),
    MapEntry("Nhắc trước 2 tuần", 20160),
  ];

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      // Initialize default options
      currentNotifyOptions.value =
          Map.from(Get.arguments['initialNotifyOptions'] ?? {});
      selectedNotifyTime.value =
          _parseTime(Get.arguments['initialDefaultNotifyTime'] ?? "06:30");

      // *** KHỞI TẠO CUSTOM REMINDERS ***
      final List<CustomReminderConfig> initialCustoms =
          Get.arguments['initialCustomReminders'] ?? [];
      currentCustomReminders.assignAll(initialCustoms);
      // Mặc định các custom reminder ban đầu đều được check
      for (var reminder in initialCustoms) {
        customReminderStates[reminder.id] = true;
      }
      // ------------------------------
    }
  }

  // Toggle default notification option
  void toggleOption(String key) {
    currentNotifyOptions[key] = !(currentNotifyOptions[key] ?? false);
  }

  // *** THÊM: Toggle custom reminder state ***
  void toggleCustomReminder(String reminderId) {
    if (customReminderStates.containsKey(reminderId)) {
      customReminderStates[reminderId] = !customReminderStates[reminderId]!;
    } else {
      // Trường hợp hiếm gặp: reminderId không tồn tại
      LoggerUtils.warning(
          "Attempted to toggle non-existent custom reminder: $reminderId");
    }
  }
  // ------------------------------------

  // Update selected time for day-based reminders
  void updateTime(TimeOfDay time) {
    selectedNotifyTime.value = time;
  }

  // Check if time picker should be shown (based on default day-based options)
  bool shouldShowTimePicker() {
    return currentNotifyOptions.entries.any((entry) {
      if (!entry.value) return false;
      final minutes = _getMinutesFromKey(entry.key);
      return minutes >= 1440; // >= 1 day
    });
  }

  // Parse time string to TimeOfDay
  TimeOfDay _parseTime(String timeString) {
    // ... (giữ nguyên)
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0); // Default time
    }
  }

  // Format TimeOfDay to string
  String formatTime(TimeOfDay time) {
    // ... (giữ nguyên)
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  // Get minutes from default option key
  int _getMinutesFromKey(String key) {
    // ... (giữ nguyên)
    if (key.contains("5 phút")) return 5;
    if (key.contains("15 phút")) return 15;
    if (key.contains("30 phút")) return 30;
    if (key.contains("1 giờ")) return 60;
    if (key.contains("2 giờ")) return 120;
    if (key.contains("1 ngày")) return 1440;
    if (key.contains("2 ngày")) return 2880;
    if (key.contains("3 ngày")) return 4320;
    if (key.contains("5 ngày")) return 7200;
    if (key.contains("1 tuần")) return 10080;
    if (key.contains("2 tuần")) return 20160;
    return 0;
  }

  // *** Custom reminder dialog temporarily disabled ***
  Future<void> showCustomReminderDialog() async {
    SnackbarUtils.showWarning("Tính năng đang được cập nhật");
  }
  // ---------------------------------------

  // *** CẬP NHẬT: Save and return result ***
  // *** CẬP NHẬT: Save and return result ***
  void saveSettings() {
    // Lọc ra các custom reminder được check
    final List<CustomReminderConfig> checkedCustomReminders =
        currentCustomReminders
            .where((reminder) => customReminderStates[reminder.id] ?? false)
            .toList(); // Lọc dựa trên state đã check

    LoggerUtils.debug(
        "Saving settings. Checked custom reminders: ${checkedCustomReminders.length}");

    Get.back(result: {
      'options':
          Map<String, bool>.from(currentNotifyOptions), // Chuyển về Map thường
      'time': formatTime(selectedNotifyTime.value),
      'customReminders':
          checkedCustomReminders, // <<< TRẢ VỀ DANH SÁCH ĐÃ LỌC >>>
    });
  }
  // --------------------------------------

  // Cancel dialog
  void cancel() {
    Get.back(result: null);
  }
}
