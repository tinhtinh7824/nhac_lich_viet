import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:scroll_date_picker/scroll_date_picker.dart';
import '../../services/lunar_service.dart';
import '../../utils/logger_utils.dart';

/// Controller quản lý state của ScrollDatePicker
class DatePickerController extends GetxController {
  Rx<DateTime> selectedDate;
  RxBool isLunar;
  Function(DateTime, bool) onDateSelected;

  // Biến để theo dõi thay đổi từng thành phần ngày
  final RxInt _lastYear = 0.obs;
  final RxInt _lastMonth = 0.obs;
  final RxInt _lastDay = 0.obs;

  DatePickerController({
    required DateTime initialDate,
    required bool initialLunar,
    required this.onDateSelected,
  })  : selectedDate = initialDate.obs,
        isLunar = initialLunar.obs;

  @override
  void onInit() {
    super.onInit();
    _lastYear.value = selectedDate.value.year;
    _lastMonth.value = selectedDate.value.month;
    _lastDay.value = selectedDate.value.day;
  }

  // Kiểm tra xem ngày được chọn có phải là hôm nay không
  bool isTodaySelected() {
    final today = DateTime.now().toLocal();
    if (isLunar.value) {
      try {
        final lunarToday = LunarService.getSolarToLunar(today);
        return selectedDate.value.year == today.year &&
            selectedDate.value.month == lunarToday.month &&
            selectedDate.value.day == lunarToday.day;
      } catch (e) {
        LoggerUtils.error("Lỗi kiểm tra ngày âm lịch hôm nay", e);
        return false;
      }
    } else {
      return selectedDate.value.year == today.year &&
          selectedDate.value.month == today.month &&
          selectedDate.value.day == today.day;
    }
  }

  // Cập nhật ngày được chọn
  void updateDate(DateTime newDate) {
    final daysInMonth = DateTime(newDate.year, newDate.month + 1, 0).day;
    final validDay = newDate.day <= daysInMonth ? newDate.day : daysInMonth;
    final validDate = DateTime(newDate.year, newDate.month, validDay);

    selectedDate.value = validDate;
  }

  // Cập nhật loại lịch
  void updateLunar(bool lunar) {
    isLunar.value = lunar;
  }

  void jumpToToday() {
    final DateTime todayGregorian = DateTime.now().toLocal();

    if (isLunar.value) {
      try {
        final lunarToday = LunarService.getSolarToLunar(todayGregorian);
        final DateTime dateToScrollTo = DateTime(
          todayGregorian.year,
          lunarToday.month,
          lunarToday.day,
        );
        updateDate(dateToScrollTo);
      } catch (e) {
        LoggerUtils.error("Lỗi lấy ngày Âm lịch cho 'Hôm nay'", e);
        updateDate(todayGregorian);
      }
    } else {
      updateDate(todayGregorian);
    }
  }

  // Xác nhận lựa chọn
  void confirmSelection() {
    onDateSelected(selectedDate.value, isLunar.value);
  }
}

/// Component hiển thị dialog chọn ngày với ScrollDatePicker
class ScrollDatePickerDialog {
  static Future<void> show({
    required BuildContext context,
    required DateTime initialDate,
    required bool isLunar,
    required Function(DateTime, bool) onDateSelected,
    String title = 'Chọn ngày diễn ra sự kiện',
    DateTime? minimumDate,
    DateTime? maximumDate,
  }) async {
    // Tạo controller để quản lý state
    final controller = DatePickerController(
      initialDate: initialDate,
      initialLunar: isLunar,
      onDateSelected: onDateSelected,
    );

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
            side: const BorderSide(
              color: Color(0xFFD6D6D6),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiêu đề dialog
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                // Lựa chọn loại lịch (âm/dương)
                Obx(() => Container(
                      width: 228.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFD6D6D6),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCalendarTypeButton(
                                'Dương Lịch',
                                !controller.isLunar.value,
                                () {
                                  controller.updateLunar(false);
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildCalendarTypeButton(
                                'Âm Lịch',
                                controller.isLunar.value,
                                () {
                                  controller.updateLunar(true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                SizedBox(height: 8.0.h),
                // Nút "Hôm nay"
                Obx(() => Visibility(
                      visible: !controller.isTodaySelected(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                          ),
                          onPressed: () => controller.jumpToToday(),
                          icon: Icon(
                            Icons.today,
                            size: 20.h,
                            color: const Color(0xFF397880),
                          ),
                          label: Text(
                            'Hôm nay',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: const Color(0xFF397880),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )),
                SizedBox(height: 8.0.h),
                // ScrollDatePicker
                Obx(() {
                  return SizedBox(
                    height: 190.h,
                    child: ScrollDatePicker(
                      indicator: Container(
                        height: 50.h,
                      ),
                      scrollViewOptions: DatePickerScrollViewOptions(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        year: ScrollViewDetailOptions(
                          isLoop: false,
                          selectedTextStyle: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212121),
                          ),
                          textStyle: TextStyle(
                            fontSize: 20.sp,
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        month: ScrollViewDetailOptions(
                          isLoop: false,
                          selectedTextStyle: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212121),
                          ),
                          textStyle: TextStyle(
                            fontSize: 20.sp,
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        day: ScrollViewDetailOptions(
                          isLoop: false,
                          selectedTextStyle: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212121),
                          ),
                          textStyle: TextStyle(
                            fontSize: 20.sp,
                            color: const Color(0xFF212121),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      options: DatePickerOptions(
                        itemExtent: 60.h,
                        perspective: 0.0000001,
                        isLoop: false,
                      ),
                      selectedDate: controller.selectedDate.value,
                      locale: const Locale('vi'),
                      onDateTimeChanged: (DateTime value) {
                        controller.updateDate(value);
                      },
                      maximumDate: maximumDate ?? DateTime(2100),
                      minimumDate: minimumDate ?? DateTime(1900),
                    ),
                  );
                }),
                const SizedBox(height: 16.0),
                // Các nút thao tác (Đóng/Chọn)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(
                        label: 'Đóng',
                        backgroundColor: const Color(0xFFD6D6D6),
                        textColor: const Color(0xFF212121),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      _buildActionButton(
                        label: 'Chọn',
                        backgroundColor: const Color(0xFF00B732),
                        textColor: Colors.white,
                        onPressed: () {
                          controller.confirmSelection();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tạo nút chọn loại lịch (Âm/Dương)
  static Widget _buildCalendarTypeButton(
      String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28.h,
        width: 100.w,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00B732) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF616161),
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
        ),
      ),
    );
  }

  /// Tạo nút hành động (Đóng/Chọn)
  static Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(
          fontSize: 18.sp,
        ),
        backgroundColor: backgroundColor,
        minimumSize: Size(120.w, 40.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
