import 'package:nhac_lich_viet/app/data/models/custom_reminder_config.dart';
// -------------------------------------------
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/modules/add_event/controllers/add_event_controller.dart';
import 'package:nhac_lich_viet/app/modules/add_event/views/notification_settings_dialog.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:day_night_time_picker/lib/state/time.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/event_category_model.dart';
import '../../../services/lunar_service.dart';
import '../../../utils/logger_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/date_widgets/scroll_date_picker_dialog.dart';
import '../../../widgets/date_widgets/scroll_time_picker_dialog.dart';

class CreateEventController extends GetxController {
  // Service instances
  final EventServices eventServices = Get.find<EventServices>();

  // Variables
  var uuid = const Uuid();

  final RxBool isEdit = false.obs;
  final Rx<Event?> editingEvent = Rx<Event?>(null);

  // Form data (reactive)
  final category = Rxn<EventCategory>();
  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final selectedDate = DateTime.now().obs;
  final selectedTime = Time.fromTimeOfDay(const TimeOfDay(hour: 8, minute: 0), 0).obs;
  final repeatType = "Không lặp lại".obs;
  final isLunar = false.obs; // Mặc định là lịch dương
  final notifyOptions = <String, bool>{
    "Nhắc khi bắt đầu sự kiện": true,
    "Nhắc trước 5 phút": false,
    "Nhắc trước 15 phút": false,
    "Nhắc trước 30 phút": false,
    "Nhắc trước 1 giờ": false,
    "Nhắc trước 2 giờ": false,
    "Nhắc trước 1 ngày": true,
    "Nhắc trước 2 ngày": false,
    "Nhắc trước 1 tuần": false,
  }.obs;

  final defaultNotifyTime = "06:30".obs;
  final RxList<CustomReminderConfig> customReminders =
      <CustomReminderConfig>[].obs;

  final repeatOptions = [
    "Không lặp lại",
    "Hằng ngày",
    "Hằng tuần",
    "Hằng tháng",
    "Hằng năm",
  ];

  String get formattedDate {
    final weekday = _getVietnameseWeekday(selectedDate.value.weekday);
    return "$weekday, ngày ${selectedDate.value.day} tháng ${selectedDate.value.month}, ${selectedDate.value.year}";
  }

  String get formattedLunarDate {
    final weekday = _getVietnameseWeekday(selectedDate.value.weekday);

    try {
      final lunarDate = LunarService.getSolarToLunar(selectedDate.value);
      return "$weekday, ngày ${lunarDate.day} tháng ${lunarDate.month} năm ${lunarDate.year} (âm lịch)";
    } catch (e) {
      LoggerUtils.error("Error getting lunar date", e);
      return "(âm lịch)";
    }
  }

  String get formattedTime {
    return "${selectedTime.value.hour.toString().padLeft(2, '0')}:${selectedTime.value.minute.toString().padLeft(2, '0')}";
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments['isEdit'] == true && Get.arguments['event'] != null) {
        isEdit.value = true;
        editingEvent.value = Get.arguments['event'] as Event;
        _populateFieldsForEdit();
        
        // Track edit event dialog shown
        try {
          Get.find<AnalyticsService>().logDialogShown(
            'edit_event_dialog',
            parameters: <String, Object>{
              'context': 'event_management',
              'event_id': editingEvent.value!.id,
              'event_type': editingEvent.value!.eventType,
            },
          );
        } catch (e) {
          LoggerUtils.debug('Analytics tracking failed: $e');
        }
      } else {
        EventCategory? initialCategory;
        if (Get.arguments['category'] != null) {
          initialCategory = Get.arguments['category'] as EventCategory;
          category.value = initialCategory;
        }
        if (Get.arguments['selectedDate'] != null) {
          selectedDate.value = Get.arguments['selectedDate'];
          selectedTime.value = Time.fromTimeOfDay(const TimeOfDay(hour: 8, minute: 0), 0);
        }

        if (initialCategory != null && !isEdit.value) {
          final categoryTitleLower = initialCategory.title.toLowerCase();
          if (categoryTitleLower.contains('sinh nhật') ||
              categoryTitleLower.contains('ngày giỗ')) {
            repeatType.value = "Hằng năm";
            LoggerUtils.debug(
                "Category is '${initialCategory.title}', setting repeatType to 'Hằng năm'.");
          }
          if (categoryTitleLower.contains('ngày giỗ')) {
            isLunar.value = true;
            LoggerUtils.debug(
                "Category is 'Ngày giỗ', setting isLunar to true.");
          }
        }
      }
    }
  }

  void _populateFieldsForEdit() {
    if (editingEvent.value != null) {
      final event = editingEvent.value!;
      titleController.text = event.title;
      noteController.text = event.description;
      selectedDate.value = event.eventDate;
      isLunar.value = event.isLunar; // Load trạng thái lịch của sự
      try {
        final timeParts = event.eventTime.split(':');
        selectedTime.value = Time(
            hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
      } catch (e) {
        selectedTime.value = Time.fromTimeOfDay(const TimeOfDay(hour: 8, minute: 0), 0);
        LoggerUtils.warning(
            'Could not parse eventTime for edit: ${event.eventTime}');
      }
      repeatType.value = _mapRepeatTypeFromApi(event.repeatType);

      // Safe access to AddEventController
      if (event.categoryId != null && event.categoryId!.isNotEmpty) {
        try {
          final addEventCtrl = Get.find<AddEventController>();
          category.value = addEventCtrl.categories
              .firstWhereOrNull((cat) => cat.id == event.categoryId);
        } catch (e) {
          LoggerUtils.warning('AddEventController not found: $e');
          category.value = null;
        }
      } else {
        category.value = null;
      }

      if (event.customReminders != null) {
        customReminders.assignAll(event.customReminders!);
      } else {
        customReminders.clear();
      }

      if (event.simpleNotificationConfig != null) {
        final config = event.simpleNotificationConfig!;
        notifyOptions["Nhắc khi bắt đầu sự kiện"] = config.notifyOnDay;
        defaultNotifyTime.value = config.notifyTime;
        _setNotifyOptionFromMinutes("Nhắc trước 5 phút", 5, config);
        _setNotifyOptionFromMinutes("Nhắc trước 15 phút", 15, config);
        _setNotifyOptionFromMinutes("Nhắc trước 30 phút", 30, config);
        _setNotifyOptionFromMinutes("Nhắc trước 1 giờ", 60, config);
        _setNotifyOptionFromMinutes("Nhắc trước 2 giờ", 120, config);
        _setNotifyOptionFromMinutes("Nhắc trước 1 ngày", 1440, config);
        _setNotifyOptionFromMinutes("Nhắc trước 2 ngày", 2880, config);
        _setNotifyOptionFromMinutes("Nhắc trước 1 tuần", 10080, config);
      } else {
        notifyOptions.forEach((key, value) {
          notifyOptions[key] =
              key == "Nhắc khi bắt đầu sự kiện" ? event.isNotify : false;
        });
        defaultNotifyTime.value = "06:30";
      }
    }
  }

  void toggleCalendarType(bool isLunarSelected) {
    isLunar.value = isLunarSelected;
  }

  void _setNotifyOptionFromMinutes(
      String key, int minutes, SimpleNotificationConfig config) {
    notifyOptions[key] = config.notifyDaysBefore.contains(minutes);
  }

  String _mapRepeatTypeToApi(String vietnameseType) {
    switch (vietnameseType) {
      case "Hằng ngày":
        return "daily";
      case "Hằng tuần":
        return "weekly";
      case "Hằng tháng":
        return "monthly";
      case "Hằng năm":
        return "yearly";
      default:
        return "none";
    }
  }

  String _mapRepeatTypeFromApi(String apiType) {
    switch (apiType) {
      case "daily":
        return "Hằng ngày";
      case "weekly":
        return "Hằng tuần";
      case "monthly":
        return "Hằng tháng";
      case "yearly":
        return "Hằng năm";
      default:
        return "Không lặp lại";
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    noteController.dispose();
    super.onClose();
  }

  Future<void> selectDateTime(BuildContext context) async {
    try {
      // Prepare initial date for picker (same as selectDate method)
      DateTime initialPickerDate = selectedDate.value;

      if (isLunar.value) {
        try {
          final lunarEquivalent = LunarService.getSolarToLunar(selectedDate.value);
          initialPickerDate = DateTime(
              lunarEquivalent.year, lunarEquivalent.month, lunarEquivalent.day);
        } catch (e) {
          LoggerUtils.error("Lỗi chuyển đổi sang ngày âm để hiển thị picker", e);
        }
      }

      DateTime? newSelectedSolarDate;
      bool newIsLunar = isLunar.value;

      await ScrollDatePickerDialog.show(
        context: context,
        initialDate: initialPickerDate,
        isLunar: isLunar.value,
        title: 'Chọn ngày diễn ra sự kiện',
        onDateSelected: (DateTime pickedDate, bool isLunarOutput) async {
          newIsLunar = isLunarOutput;
          if (newIsLunar) {
            try {
              newSelectedSolarDate = LunarService.getLunarToSolar(
                pickedDate.day,
                pickedDate.month,
                pickedDate.year,
              );
            } catch (e) {
              SnackbarUtils.showError('Ngày âm lịch không hợp lệ.');
              newSelectedSolarDate = null;
              return;
            }
          } else {
            newSelectedSolarDate = pickedDate;
          }

          // Update date and lunar setting
          if (newSelectedSolarDate != null) {
            isLunar.value = newIsLunar;
            selectedDate.value = newSelectedSolarDate!;

            LoggerUtils.debug(
                "Đã cập nhật ngày: ${selectedDate.value.toIso8601String()}, isLunar: ${isLunar.value}");

            // Check if context is still mounted before showing time picker
            if (!context.mounted) {
              LoggerUtils.debug("Context no longer mounted");
              return;
            }

            // Show time picker after date selection
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: selectedTime.value.hour,
                minute: selectedTime.value.minute,
              ),
              helpText: 'Chọn thời gian',
            );

            if (pickedTime != null) {
              selectedTime.value = Time.fromTimeOfDay(pickedTime, 0);
              LoggerUtils.debug(
                  "Đã cập nhật giờ: $formattedTime");
            }
          }
        },
      );
    } catch (e) {
      LoggerUtils.error("Error selecting date time", e);
      SnackbarUtils.showError("Có lỗi xảy ra khi chọn ngày giờ");
    }
  }

  Future<void> selectDate(BuildContext context) async {
    try {
      // Prepare initial date for picker
      DateTime initialPickerDate = selectedDate.value;

      if (isLunar.value) {
        try {
          final lunarEquivalent = LunarService.getSolarToLunar(selectedDate.value);
          initialPickerDate = DateTime(
              lunarEquivalent.year, lunarEquivalent.month, lunarEquivalent.day);
        } catch (e) {
          LoggerUtils.error("Lỗi chuyển đổi sang ngày âm để hiển thị picker", e);
        }
      }

      DateTime? newSelectedSolarDate;
      bool newIsLunar = isLunar.value;

      await ScrollDatePickerDialog.show(
        context: context,
        initialDate: initialPickerDate,
        isLunar: isLunar.value,
        title: 'Chọn ngày diễn ra sự kiện',
        onDateSelected: (DateTime pickedDate, bool isLunarOutput) {
          newIsLunar = isLunarOutput;
          if (newIsLunar) {
            try {
              newSelectedSolarDate = LunarService.getLunarToSolar(
                pickedDate.day,
                pickedDate.month,
                pickedDate.year,
              );
            } catch (e) {
              SnackbarUtils.showError('Ngày âm lịch không hợp lệ.');
              newSelectedSolarDate = null;
            }
          } else {
            newSelectedSolarDate = pickedDate;
          }
        },
      );

      if (newSelectedSolarDate == null) {
        LoggerUtils.debug("Người dùng đã hủy hoặc chọn ngày không hợp lệ.");
        return;
      }

      isLunar.value = newIsLunar;
      selectedDate.value = newSelectedSolarDate!;
      LoggerUtils.debug(
          "Đã cập nhật ngày: ${selectedDate.value.toIso8601String()}, isLunar: ${isLunar.value}");
    } catch (e) {
      LoggerUtils.error("Error selecting date", e);
      SnackbarUtils.showError("Có lỗi xảy ra khi chọn ngày");
    }
  }

  Future<void> selectTime(BuildContext context) async {
    try {
      // Show custom time picker dialog like lich-am
      await ScrollTimePickerDialog.show(
        context: context,
        initialTime: TimeOfDay(
          hour: selectedTime.value.hour,
          minute: selectedTime.value.minute,
        ),
        title: 'Ngày giờ',
        onTimeSelected: (TimeOfDay pickedTime) {
          selectedTime.value = Time.fromTimeOfDay(pickedTime, 0);
          LoggerUtils.debug("Đã cập nhật giờ: $formattedTime");
        },
      );
    } catch (e) {
      LoggerUtils.error("Error selecting time", e);
      SnackbarUtils.showError("Có lỗi xảy ra khi chọn giờ");
    }
  }

  Future<void> showNotificationSettingsDialog() async {
    final result = await Get.dialog<Map<String, dynamic>>(
      const NotificationSettingsDialog(),
      arguments: {
        'initialNotifyOptions': Map<String, bool>.from(notifyOptions),
        'initialDefaultNotifyTime': defaultNotifyTime.value,
        'initialCustomReminders': customReminders.toList(),
      },
    );

    if (result != null) {
      notifyOptions.value = Map<String, bool>.from(result['options']);
      defaultNotifyTime.value = result['time'] as String;
      customReminders.value =
          List<CustomReminderConfig>.from(result['customReminders'] ?? []);
      LoggerUtils.debug(
          "Updated custom reminders from dialog: ${customReminders.length}");
    }
  }

  Future<void> submitEvent() async {
    if (titleController.text.trim().isEmpty) {
      SnackbarUtils.showWarning("Vui lòng nhập tiêu đề sự kiện");
      return;
    }

    // Track save event action
    try {
      Get.find<AnalyticsService>().logDialogAction(
        isEdit.value ? 'edit_event_dialog' : 'add_event_dialog',
        'save_event',
        parameters: <String, Object>{
          'event_type': isEdit.value ? 'edit' : 'create',
          'is_lunar': isLunar.value,
          'has_repeat': repeatType.value != "Không lặp lại",
          'has_notification': notifyOptions.values.any((v) => v) || customReminders.isNotEmpty,
        },
      );
    } catch (e) {
      LoggerUtils.debug('Analytics tracking failed: $e');
    }

    try {
      final bool shouldNotify =
          notifyOptions.values.any((v) => v) || customReminders.isNotEmpty;
      final List<int> daysBeforeList = [];
      if (notifyOptions["Nhắc trước 5 phút"] == true) daysBeforeList.add(5);
      if (notifyOptions["Nhắc trước 15 phút"] == true) daysBeforeList.add(15);
      if (notifyOptions["Nhắc trước 30 phút"] == true) daysBeforeList.add(30);
      if (notifyOptions["Nhắc trước 1 giờ"] == true) daysBeforeList.add(60);
      if (notifyOptions["Nhắc trước 2 giờ"] == true) daysBeforeList.add(120);
      if (notifyOptions["Nhắc trước 1 ngày"] == true) daysBeforeList.add(1440);
      if (notifyOptions["Nhắc trước 2 ngày"] == true) daysBeforeList.add(2880);
      if (notifyOptions["Nhắc trước 1 tuần"] == true) daysBeforeList.add(10080);

      final notificationConfig = SimpleNotificationConfig(
        notifyOnDay: notifyOptions["Nhắc khi bắt đầu sự kiện"] ?? false,
        notifyDaysBefore: daysBeforeList,
        notifyTime: defaultNotifyTime.value,
      );

      DateTime? originalLunarDateValue;
      if (isLunar.value) {
        // Nếu là sự kiện âm lịch, ta cần tính ngày âm lịch từ ngày dương lịch đã chọn
        final lunarEquivalent =
            LunarService.getSolarToLunar(selectedDate.value);
        originalLunarDateValue = DateTime(
          lunarEquivalent.year,
          lunarEquivalent.month,
          lunarEquivalent.day,
        );
      }

      final eventData = Event(
        id: isEdit.value ? editingEvent.value!.id : uuid.v4(),
        title: titleController.text.trim(),
        description: noteController.text.trim(),
        eventType: EventTypeEnum.user_event.value,
        isNotify: shouldNotify,
        eventDate: DateTime(
          selectedDate.value.year,
          selectedDate.value.month,
          selectedDate.value.day,
          selectedTime.value.hour,
          selectedTime.value.minute,
        ),
        eventTime: formattedTime,
        repeatType: _mapRepeatTypeToApi(repeatType.value),
        iconUrl: isEdit.value
            ? editingEvent.value?.iconUrl
            : category.value?.iconUrl,
        bannerUrl: isEdit.value
            ? editingEvent.value?.bannerUrl
            : category.value?.bannerUrl,
        showOnCalendar: true,
        showNotificationOnOpen: false,
        categoryId:
            isEdit.value ? editingEvent.value?.categoryId : category.value?.id,
        simpleNotificationConfig: notificationConfig,
        customReminders: customReminders.toList(),
        createdAt:
            isEdit.value ? editingEvent.value!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        originalEventId:
            isEdit.value ? editingEvent.value!.originalEventId : null,
        isOccurrence: isEdit.value ? editingEvent.value!.isOccurrence : false,
        isLunar: isLunar.value,
        originalLunarDate: originalLunarDateValue,
        subtitle: isEdit.value ? editingEvent.value!.subtitle : null,
        detail: isEdit.value ? editingEvent.value!.detail : null,
        wishes: isEdit.value ? editingEvent.value!.wishes : null,
      );

      bool success = false;
      if (isEdit.value) {
        success = await eventServices.updateEvent(eventData);
      } else {
        final addedEvent = await eventServices.addEvent(eventData);
        success = addedEvent != null;
      }

      if (success) {
        if (category.value != null) {
          Get.offAllNamed(
            Routes.EVENTS,
            arguments: {'category': category.value},
          );
        } else {
          Get.offAllNamed(Routes.EVENTS);
        }
      } else {
        Get.back(result: false);
        SnackbarUtils.showError(
            isEdit.value ? "Không thể cập nhật sự kiện" : "Không thể lưu sự kiện");
      }
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Error submitting event (isEdit: ${isEdit.value})', e, stackTrace);
      Get.back(result: false);
      SnackbarUtils.showError("Đã xảy ra lỗi: ${e.toString()}");
    }
  }

  String _getVietnameseWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return "Thứ 2";
      case 2:
        return "Thứ 3";
      case 3:
        return "Thứ 4";
      case 4:
        return "Thứ 5";
      case 5:
        return "Thứ 6";
      case 6:
        return "Thứ 7";
      case 7:
        return "Chủ nhật";
      default:
        return "";
    }
  }
}
