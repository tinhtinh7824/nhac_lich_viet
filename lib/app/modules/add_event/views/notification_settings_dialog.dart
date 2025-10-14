// File: app/modules/add_event/views/notification_settings_dialog.dart
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/notification_settings_controller.dart';

// Widget hiển thị dialog cài đặt thông báo
class NotificationSettingsDialog
    extends GetView<NotificationSettingsController> {
  const NotificationSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller only if not exists
    if (!Get.isRegistered<NotificationSettingsController>()) {
      Get.put(NotificationSettingsController());
    }

    return AlertDialog(
      // --- Tiêu đề Dialog ---
      title: const Text(
        "NHẮC NHỞ",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
      // --- Nội dung Dialog (có thể cuộn) ---
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite, // Chiếm hết chiều rộng có thể
          child: Column(
            mainAxisSize: MainAxisSize.min, // Co lại theo nội dung
            children: [
              // --- Hiển thị các tùy chọn nhắc nhở MẶC ĐỊNH ---
              ...controller.displayOptions.map((entry) {
                final String optionKey = entry.key;
                // Sử dụng Obx để tự động cập nhật khi state thay đổi
                return Obx(() => _buildOptionRow(
                      text: optionKey, // Text hiển thị
                      // Lấy trạng thái check từ controller
                      isChecked:
                          controller.currentNotifyOptions[optionKey] ?? false,
                      // Hàm xử lý khi nhấn vào
                      onTap: () => controller.toggleOption(optionKey),
                    ));
              }).toList(),

              // <<< THÊM PHẦN HIỂN THỊ CUSTOM REMINDERS >>>
              // Sử dụng Obx để lắng nghe thay đổi trong danh sách custom reminders
              Obx(() {
                // Chỉ hiển thị nếu danh sách custom reminders không rỗng
                if (controller.currentCustomReminders.isNotEmpty) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(
                          height: 20, thickness: 1), // Đường kẻ phân cách
                      // Lặp qua danh sách custom reminders và tạo widget cho mỗi cái
                      ...controller.currentCustomReminders.map((reminder) {
                        // Sử dụng lại _buildOptionRow để hiển thị thống nhất
                        return _buildOptionRow(
                          text: reminder
                              .getDisplayText(), // Lấy text hiển thị từ model
                          // Lấy trạng thái check từ map state trong controller
                          isChecked:
                              controller.customReminderStates[reminder.id] ??
                                  false,
                          // Hàm xử lý khi nhấn vào custom reminder
                          onTap: () =>
                              controller.toggleCustomReminder(reminder.id),
                        );
                      }).toList(),
                    ],
                  );
                } else {
                  // Nếu danh sách rỗng, không hiển thị gì
                  return const SizedBox.shrink();
                }
              }),
              // <<< KẾT THÚC PHẦN THÊM CUSTOM REMINDERS >>>

              const Divider(
                  height: 20, thickness: 1), // Đường kẻ phân cách cuối cùng

              // Custom reminder temporarily disabled to prevent crashes

              // --- Hiển thị Time Picker (cho các tùy chọn mặc định >= 1 ngày) ---
              // Sử dụng Obx để ẩn/hiện dựa trên state trong controller
              Obx(() => controller.shouldShowTimePicker()
                  ? Column(
                      children: [
                        const Divider(height: 20),
                        _buildTimePicker(
                            context), // Hàm build time picker giữ nguyên
                      ],
                    )
                  : const SizedBox.shrink()), // Không hiển thị nếu không cần
            ],
          ),
        ),
      ),
      // --- Các nút Action (Đóng, OK) --- (Giữ nguyên)
      actions: [
        TextButton(
          child: Text(
            "Đóng",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: controller.cancel, // Gọi hàm cancel trong controller
        ),
        TextButton(
          child: Text(
            "OK",
            style: TextStyle(
              color: Color(0xFF0F5925), // Màu xanh lá cây
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: controller.saveSettings, // Gọi hàm lưu trong controller
        ),
      ],
      // --- Style của Dialog --- (Giữ nguyên)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      contentPadding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
      actionsPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    );
  }

  // --- Hàm Helper để tạo một hàng tùy chọn (dùng cho cả mặc định và tùy chỉnh) ---
  Widget _buildOptionRow({
    required String text, // Text hiển thị của tùy chọn
    required bool isChecked, // Trạng thái checked
    required VoidCallback onTap, // Hàm xử lý khi nhấn
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r), // Bo tròn hiệu ứng nhấn
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0), // Padding dọc
        child: Row(
          children: [
            // Icon checkbox (checked/unchecked) using Flutter icons
            Icon(
              isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 24.w,
              color: isChecked ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            // Text của tùy chọn
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- Kết thúc hàm Helper ---

  // --- Hàm Build Time Picker --- (Giữ nguyên)
  Widget _buildTimePicker(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Giờ nhắc:",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
          ),
          InkWell(
            onTap: () async {
              // Use Flutter built-in time picker instead
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: controller.selectedNotifyTime.value,
                helpText: 'Chọn thời gian nhắc nhở',
              );

              if (pickedTime != null) {
                controller.selectedNotifyTime.value = pickedTime;
              }
            },
            // Hiển thị ô giờ/phút có thể nhấn
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              // Sử dụng Obx để cập nhật thời gian hiển thị
              child: Obx(() => Text(
                    controller.formatTime(controller.selectedNotifyTime.value),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
