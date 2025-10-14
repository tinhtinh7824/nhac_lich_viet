import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Monthly calendar dialog for selecting dates
class MonthlyCalendarDialog {
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
  }) async {
    final now = DateTime.now();

    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      helpText: title ?? 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
      locale: const Locale('vi', 'VN'),
    );
  }

  /// Show with GetX dialog
  static Future<DateTime?> showGetX({
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
  }) async {
    DateTime? selectedDate = initialDate ?? DateTime.now();

    final result = await Get.dialog<DateTime>(
      AlertDialog(
        title: Text(title ?? 'Chọn ngày'),
        content: SizedBox(
          height: 300,
          width: 300,
          child: CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: firstDate ?? DateTime(1900),
            lastDate: lastDate ?? DateTime(2100),
            onDateChanged: (date) {
              selectedDate = date;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: selectedDate),
            child: const Text('Chọn'),
          ),
        ],
      ),
    );

    return result;
  }
}
