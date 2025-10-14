import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/create_event_controller.dart';

class CreateEventView extends GetView<CreateEventController> {
  const CreateEventView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/create_event_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventTitleField(),
                    SizedBox(height: 24.h),
                    _buildDateField(),
                    SizedBox(height: 16.h),
                    _buildTimeField(),
                    SizedBox(height: 24.h),
                    _buildRepeatEventField(),
                    SizedBox(height: 24.h),
                    _buildNotificationField(),
                    SizedBox(height: 24.h),
                    _buildNoteField(),
                    SizedBox(height: 32.h),
                    _buildSubmitButton(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 60.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 24.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Obx(() => Text(
                controller.isEdit.value ? 'Cập nhật sự kiện' : 'Tạo sự kiện mới',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tên sự kiện:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextField(
            controller: controller.titleController,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập tên sự kiện',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16.sp,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(12.w),
                child: Obx(() {
                  // Thử sử dụng icon từ category trước
                  if (controller.category.value?.iconUrl != null) {
                    return Image.network(
                      controller.category.value!.iconUrl!,
                      width: 24.w,
                      height: 24.w,
                      errorBuilder: (context, error, stackTrace) {
                        return _getCategoryIcon();
                      },
                    );
                  }
                  // Fallback sử dụng icon local dựa trên category
                  return _getCategoryIcon();
                }),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngày diễn ra:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () => controller.selectDate(Get.context!),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() => Text(
                    controller.isLunar.value ? controller.formattedLunarDate : controller.formattedDate,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  )),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giờ diễn ra:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () => controller.selectTime(Get.context!),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() => Text(
                    controller.formattedTime,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  )),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatEventField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sự kiện lặp lại:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButtonHideUnderline(
            child: Obx(() => DropdownButton<String>(
              value: controller.repeatType.value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 20.sp,
              ),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  controller.repeatType.value = newValue;
                }
              },
              items: controller.repeatOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                        color: Colors.grey[600],
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(value),
                    ],
                  ),
                );
              }).toList(),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông báo:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () => controller.showNotificationSettingsDialog(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_none,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Obx(() {
                    final enabledOptions = <String>[];

                    // Kiểm tra các option đã bật
                    controller.notifyOptions.forEach((key, value) {
                      if (value) {
                        if (key.contains('ngày') && key != 'Nhắc khi bắt đầu sự kiện') {
                          enabledOptions.add('$key lúc ${controller.defaultNotifyTime.value}');
                        } else {
                          enabledOptions.add(key);
                        }
                      }
                    });

                    // Thêm custom reminders
                    for (var reminder in controller.customReminders) {
                      enabledOptions.add(reminder.getDisplayText());
                    }

                    if (enabledOptions.isEmpty) {
                      return Text(
                        'Không nhắc nhở',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: enabledOptions.map((option) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Text(
                            '- $option',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú:',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFE5E5E5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: TextField(
            controller: controller.noteController,
            maxLines: 4,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Ghi chú (không bắt buộc)',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16.sp,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(top: 12.h, left: 12.w, right: 8.w),
                child: Icon(
                  Icons.edit_note,
                  color: Colors.grey[600],
                  size: 20.sp,
                ),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: () => controller.submitEvent(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Lưu',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon() {
    final category = controller.category.value;

    // Nếu có category và iconUrl, sử dụng CachedNetworkImage như lich-am
    if (category?.iconUrl != null && category!.iconUrl!.isNotEmpty) {
      return SizedBox(
        width: 24.w,
        height: 24.w,
        child: CachedNetworkImage(
          imageUrl: category.iconUrl!,
          fit: BoxFit.contain,
          placeholder: (context, url) => Icon(
            Icons.event,
            size: 24.w,
            color: Colors.orange,
          ),
          errorWidget: (context, url, error) => Icon(
            Icons.event,
            size: 24.w,
            color: Colors.orange,
          ),
        ),
      );
    }

    // Fallback sử dụng asset local với logic cũ
    return Icon(
      Icons.event,
      size: 24.w,
      color: Colors.orange,
    );
  }
}