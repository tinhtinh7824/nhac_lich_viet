import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Controller quản lý state của ScrollTimePicker
class TimePickerController extends GetxController {
  final Rx<TimeOfDay> selectedTime;
  final Function(TimeOfDay) onTimeSelected;

  TimePickerController({
    required TimeOfDay initialTime,
    required this.onTimeSelected,
  }) : selectedTime = initialTime.obs;

  // Cập nhật giờ được chọn
  void updateTime(TimeOfDay newTime) {
    selectedTime.value = newTime;
  }

  // Xác nhận lựa chọn
  void confirmSelection() {
    onTimeSelected(selectedTime.value);
  }
}

/// Component hiển thị dialog chọn giờ với ScrollTimePicker
class ScrollTimePickerDialog {
  static Future<void> show({
    required BuildContext context,
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimeSelected,
    String title = 'Ngày giờ',
  }) async {
    // Tạo controller để quản lý state
    final controller = TimePickerController(
      initialTime: initialTime,
      onTimeSelected: onTimeSelected,
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
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiêu đề dialog
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),

                // Icon mặt trời
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF87CEEB), // Sky blue
                        Color(0xFFE0F6FF), // Light blue
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFFD00), // Bright yellow
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Time Picker Scroll Wheels
                Obx(() {
                  return Container(
                    height: 150.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour picker
                        Expanded(
                          child: _buildScrollWheel(
                            selectedValue: controller.selectedTime.value.hour,
                            maxValue: 23,
                            onSelectedItemChanged: (value) {
                              controller.updateTime(TimeOfDay(
                                hour: value,
                                minute: controller.selectedTime.value.minute,
                              ));
                            },
                          ),
                        ),

                        // "Giờ" label
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'Giờ',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // Minute picker
                        Expanded(
                          child: _buildScrollWheel(
                            selectedValue: controller.selectedTime.value.minute,
                            maxValue: 59,
                            onSelectedItemChanged: (value) {
                              controller.updateTime(TimeOfDay(
                                hour: controller.selectedTime.value.hour,
                                minute: value,
                              ));
                            },
                          ),
                        ),

                        // "Phút" label
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'Phút',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: 24.h),

                // Các nút thao tác (Hủy/Đồng ý)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      label: 'Hủy',
                      backgroundColor: const Color(0xFFD6D6D6),
                      textColor: const Color(0xFF212121),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    _buildActionButton(
                      label: 'Đồng ý',
                      backgroundColor: const Color(0xFF00B732),
                      textColor: Colors.white,
                      onPressed: () {
                        controller.confirmSelection();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tạo scroll wheel cho giờ/phút
  static Widget _buildScrollWheel({
    required int selectedValue,
    required int maxValue,
    required Function(int) onSelectedItemChanged,
  }) {
    return Container(
      height: 150.h,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 50.h,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelectedItemChanged,
        controller: FixedExtentScrollController(initialItem: selectedValue),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: maxValue + 1,
          builder: (context, index) {
            final isSelected = index == selectedValue;
            return Container(
              alignment: Alignment.center,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isSelected ? 24.sp : 18.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Color(0xFF007AFF) : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Tạo nút hành động (Hủy/Đồng ý)
  static Widget _buildActionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(
          fontSize: 16.sp,
        ),
        backgroundColor: backgroundColor,
        minimumSize: Size(100.w, 40.h),
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}