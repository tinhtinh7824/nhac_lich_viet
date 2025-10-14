import 'package:nhac_lich_viet/app/data/models/custom_reminder_config.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/widgets/date_widgets/monthly_calendar_dialog.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CustomReminderDialog extends StatefulWidget {
  const CustomReminderDialog({super.key});

  @override
  State<CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<CustomReminderDialog> {
  CustomReminderType _selectedType = CustomReminderType.countdown;
  int _hours = 0;
  int _minutes = 5;
  DateTime? _selectedDate; // Giữ nguyên là nullable từ code gốc
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  void _selectSpecificDate() async {
    final DateTime? pickedDate = await MonthlyCalendarDialog.show(
      context,
      initialDate: _selectedDate ?? DateTime.now(),
      title: 'Chọn ngày nhắc',
    );

    if (pickedDate != null) {
      setState(() {
        // Cập nhật _selectedDate với ngày từ pickedDate và giờ/phút từ _selectedTime hiện tại
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime.hour, // Giữ giờ từ _selectedTime
          _selectedTime.minute, // Giữ phút từ _selectedTime
        );
      });
      _selectSpecificTime(); // Vẫn gọi _selectSpecificTime sau khi chọn ngày
    }
  }

  void _selectSpecificTime() async {
    // Xác định ngày cơ sở: nếu _selectedDate đã có, dùng nó; nếu không, dùng ngày hiện tại.
    // Điều này quan trọng để DateTime constructor bên dưới không lỗi nếu _selectedDate là null.
    final DateTime baseDateForTimeSelection = _selectedDate ?? DateTime.now();

    Time initialTime = Time.fromTimeOfDay(_selectedTime, 0);

    Navigator.of(context).push(
      showPicker(
        context: context,
        value: initialTime,
        onChange: (Time time) {
          setState(() {
            // Cập nhật _selectedTime với giờ/phút mới
            _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
            // Cập nhật _selectedDate với ngày từ baseDateForTimeSelection và giờ/phút mới
            _selectedDate = DateTime(
              baseDateForTimeSelection.year,
              baseDateForTimeSelection.month,
              baseDateForTimeSelection.day,
              time.hour, // Giờ mới
              time.minute, // Phút mới
            );
          });
        },
        minuteInterval: TimePickerInterval.ONE,
        okText: "Đồng ý",
        cancelText: "Hủy",
        hourLabel: "Giờ",
        minuteLabel: "Phút",
        iosStylePicker: true,
        okStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp),
        cancelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp),
        is24HrFormat: true,
      ),
    );
  }

  void _selectCountdownTime() async {
    Time initialTime = Time(hour: _hours, minute: _minutes);
    Navigator.of(context).push(
      showPicker(
        context: context,
        value: initialTime,
        disableHour: false,
        disableMinute: false,
        maxHour: 23,
        maxMinute: 59,
        minuteInterval: TimePickerInterval.ONE,
        okText: "Đồng ý",
        cancelText: "Hủy",
        hourLabel: "Giờ",
        minuteLabel: "Phút",
        iosStylePicker: true,
        okStyle: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp),
        cancelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp),
        is24HrFormat: true,
        onChange: (Time time) {
          setState(() {
            _hours = time.hour;
            _minutes = time.minute;
          });
        },
      ),
    );
  }

  void _submit() {
    final uuid = Uuid();
    CustomReminderConfig? result;
    if (_selectedType == CustomReminderType.countdown) {
      if (_hours > 0 || _minutes > 0) {
        result = CustomReminderConfig(
          id: uuid.v4(),
          type: CustomReminderType.countdown,
          countdownHours: _hours,
          countdownMinutes: _minutes,
        );
      } else {
        SnackbarUtils.showError(
          'Vui lòng chọn giờ hoặc phút cho đếm ngược.',
        );
        return;
      }
    } else {
      // CustomReminderType.specificDate
      // Trong trường hợp này, _selectedDate đã chứa cả thông tin ngày và giờ chính xác
      // do logic trong _selectSpecificDate và _selectSpecificTime đã cập nhật nó.
      if (_selectedDate != null) {
        final finalSelectedDateTime =
            _selectedDate!; // Sử dụng trực tiếp _selectedDate

        if (finalSelectedDateTime.isBefore(DateTime.now())) {
          SnackbarUtils.showError(
            'Vui lòng chọn ngày và giờ trong tương lai.',
          );
          return;
        }
        result = CustomReminderConfig(
          id: uuid.v4(),
          type: CustomReminderType.specificDate,
          specificDateTime: finalSelectedDateTime,
        );
      } else {
        SnackbarUtils.showError(
          'Vui lòng chọn ngày và giờ cụ thể.',
        );
        return;
      }
    }

    // result is guaranteed to be non-null here due to logic above
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dayFormatter = DateFormat('dd/MM/yyyy');
    // final DateFormat timeFormatter = DateFormat('HH:mm'); // Không còn sử dụng trực tiếp

    return AlertDialog(
      title: const Text(
        "Nhắc trước sự kiện:",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<CustomReminderType>(
                title: const Text('Đếm ngược'),
                value: CustomReminderType.countdown,
                groupValue: _selectedType,
                onChanged: (CustomReminderType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              AnimatedOpacity(
                opacity:
                    _selectedType == CustomReminderType.countdown ? 1.0 : 0.2,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: _selectedType != CustomReminderType.countdown,
                  child: Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: GestureDetector(
                      onTap: _selectCountdownTime,
                      child: Row(
                        children: [
                          _buildTimeInputBox(_hours.toString(), "Giờ"),
                          // Thêm SizedBox để có khoảng cách như bạn đã có trong code gốc
                          // của file được cung cấp ban đầu (nếu có).
                          // Nếu code gốc của bạn là _buildTimeInputBox(_minutes.toString(), "   Phút"),
                          // thì không cần SizedBox ở đây.
                          SizedBox(
                              width: 10
                                  .w), // GIỮ NGUYÊN HOẶC THAY ĐỔI THEO CODE GỐC CỦA BẠN
                          _buildTimeInputBox(
                              _minutes.toString(),
                              _selectedType == CustomReminderType.countdown
                                  ? "   Phút"
                                  : "Phút"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              RadioListTile<CustomReminderType>(
                title: const Text('Ngày cụ thể'),
                value: CustomReminderType.specificDate,
                groupValue: _selectedType,
                onChanged: (CustomReminderType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              AnimatedOpacity(
                opacity: _selectedType == CustomReminderType.specificDate
                    ? 1.0
                    : 0.5,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: _selectedType != CustomReminderType.specificDate,
                  child: Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _selectSpecificDate,
                          child: _buildDateDisplayBox(
                            _selectedDate == null
                                ? "Chọn ngày"
                                : "Ngày ${dayFormatter.format(_selectedDate!)}",
                          ),
                        ),
                        // Điều kiện if này vẫn giữ nguyên từ code gốc của bạn
                        if (_selectedType ==
                            CustomReminderType.specificDate) ...[
                          SizedBox(height: 8.h),
                          Column(
                            // Giữ nguyên cấu trúc Column từ code gốc
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Vào lúc:",
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 8.h),
                              // THÊM GestureDetector ở đây để bọc Row giờ/phút
                              GestureDetector(
                                onTap: _selectSpecificTime, // Gọi hàm chọn giờ
                                child: Row(
                                  children: [
                                    _buildTimeInputBox(
                                        _selectedTime.hour
                                            .toString()
                                            .padLeft(2, '0'),
                                        "Giờ"),
                                    SizedBox(
                                        width:
                                            10.w), // Giữ SizedBox từ code gốc
                                    _buildTimeInputBox(
                                        _selectedTime.minute
                                            .toString()
                                            .padLeft(2, '0'),
                                        "Phút"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                elevation: 0,
              ),
              child: Text(
                "Đóng",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                    0xFF0F5925), // Sử dụng Color thay vì const Color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                elevation: 0,
              ),
              child: Text(
                "Chọn",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }

  Widget _buildTimeInputBox(String value, String label) {
    return Expanded(
      child: Container(
        height: 60.h,
        // width: double.infinity, // Bỏ width này đi vì đã có Expanded
        padding: EdgeInsets.symmetric(
            horizontal: label == "   Phút"
                ? 15.w
                : 20.w), // Điều chỉnh padding cho "   Phút" nếu cần
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFD6D6D6)
                    .withOpacity(1.0), // Sử dụng Color thay vì const Color
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(value,
                  style:
                      TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500)),
            ),
            Text(label, style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDisplayBox(String value) {
    return Container(
      height: 40.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
// END REPLACE views/custom_reminder_dialog.dart
