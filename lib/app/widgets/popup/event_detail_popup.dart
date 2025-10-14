// import 'dart:math';

// import 'package:nhac_lich_viet/app/data/models/event_model.dart';
// import 'package:nhac_lich_viet/app/theme/app_colors.dart';
// import 'package:nhac_lich_viet/config/assets_path.dart'; // Đảm bảo có đường dẫn icon đúng
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart'; // Import intl để định dạng

// class EventDetailPopup extends StatelessWidget {
//   final Event event;

//   const EventDetailPopup({Key? key, required this.event}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     // Lấy theme hiện tại để quyết định màu chữ
//     final textTheme = Theme.of(context).textTheme;
//     final Color primaryTextColor =
//         textTheme.bodyLarge?.color ?? AppColors.textPrimary;
//     final Color secondaryTextColor =
//         textTheme.bodyMedium?.color ?? AppColors.textSecondary;

//     // Màu sắc từ design
//     const Color dayNumberColor = AppColors.primaryDark;
//     const Color buttonTextColor = Color(0xFFD32F2F); // Màu đỏ cho nút
//     final Color buttonBorderColor = buttonTextColor.withOpacity(0.8);

//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12.r), // Bo góc dialog
//       ),
//       elevation: 0,
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
//         decoration: BoxDecoration(
//           color: Colors.white, // Nền trắng cho nội dung
//           borderRadius: BorderRadius.circular(12.r),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min, // Co lại theo nội dung
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Align(
//               alignment: Alignment.topRight,
//               child: GestureDetector(
//                 onTap: () {
//                   Get.back(); // Đóng popup khi nhấn vào icon
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Color(0xFFD6D6D6), // Màu nền cho icon
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10.r,
//                         offset: Offset(0, 5.h),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Icon(
//                       Icons.close,
//                       size: 24.r,
//                       color: primaryTextColor,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             // Số ngày lớn
//             Text(
//               event.eventDate.day.toString(),
//               style: TextStyle(
//                 fontSize: 100.sp, // Cỡ chữ lớn hơn
//                 fontWeight: FontWeight.bold,
//                 color: dayNumberColor,
//                 height: 1.0, // Giảm chiều cao dòng
//               ),
//             ),
//             SizedBox(height: 5.h),

//             // Tháng và Năm
//             Text(
//               'Tháng ${event.eventDate.month} năm ${event.eventDate.year}',
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w500,
//                 color: primaryTextColor,
//               ),
//             ),
//             SizedBox(height: 15.h),

//             // Icon và Tiêu đề sự kiện
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 CachedNetworkImage(
//                   imageUrl: event.iconUrl ?? '',
//                   width: 24.w,
//                   height: 24.h,
//                   fit: BoxFit.contain,
//                 ),
//                 SizedBox(width: 8.w),
//                 Flexible(
//                   child: Text(
//                     event.title,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 17.sp, // Cỡ chữ lớn hơn
//                       fontWeight: FontWeight.bold,
//                       color: primaryTextColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 15.h),

//             // Đường kẻ trang trí
//             // Thay 'ImagesPath.decorativeDivider' bằng đường dẫn thực tế
//             Image.asset(
//               IconsPath.lineCalendar,
//               fit: BoxFit.contain,
//             ),
//             SizedBox(height: 15.h),

//             // Lời chúc/Sub-header sự kiện
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Icon hoa hồng (lấy từ asset hoặc IconData)
//                 // Thay 'ImagesPath.roseIcon' bằng đường dẫn/IconData thực tế

//                 SizedBox(width: 6.w),
//                 Flexible(
//                   child: Text(
//                     // Tạo lời chúc dựa trên tiêu đề (có thể cần logic phức tạp hơn)
//                     event.wishes ?? '',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.bold,
//                       color: primaryTextColor,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 10.h),

//             // Mô tả sự kiện
//             Container(
//               constraints:
//                   BoxConstraints(maxHeight: 150.h), // Giới hạn chiều cao mô tả
//               child: SingleChildScrollView(
//                 // Cho phép cuộn nếu mô tả dài
//                 child: Text(
//                   event.description.isNotEmpty
//                       ? event.description
//                       : (event.detail ?? ''),
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     color: secondaryTextColor,
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 25.h),

//             // // Nút "Gửi lời chúc" (Style theo design)
//             // OutlinedButton.icon(
//             //   onPressed: () {
//             //     // Tạm thời chỉ đóng popup
//             //     Get.back();
//             //     // TODO: Triển khai chức năng gửi lời chúc sau
//             //   },
//             //   icon:
//             //       Icon(Icons.send_outlined, size: 20.r, color: buttonTextColor),
//             //   label: Text(
//             //     'Gửi lời chúc tốt đẹp',
//             //     style: TextStyle(
//             //         fontSize: 16.sp,
//             //         color: buttonTextColor,
//             //         fontWeight: FontWeight.w600),
//             //   ),
//             //   style: OutlinedButton.styleFrom(
//             //     side: BorderSide(
//             //         color: buttonBorderColor, width: 1.5.w), // Viền đỏ
//             //     padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
//             //     shape: RoundedRectangleBorder(
//             //       borderRadius: BorderRadius.circular(8.r),
//             //     ),
//             //   ),
//             // ),
//             // SizedBox(height: 10.h), // Khoảng cách nhỏ dưới cùng
//           ],
//         ),
//       ),
//     );
//   }
// }
// START REPLACE app/widgets/popup/event_detail_popup.dart
import 'dart:math';

import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart'; // <<< THÊM IMPORT
import 'package:nhac_lich_viet/app/services/event_services.dart'; // <<< THÊM IMPORT
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:nhac_lich_viet/config/assets_path.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Import intl để định dạng
import 'package:share_plus/share_plus.dart';

class EventDetailPopup extends StatelessWidget {
  final Event event;

  const EventDetailPopup({Key? key, required this.event}) : super(key: key);

  // Hàm hiển thị dialog xác nhận xóa
  void _showDeleteConfirmation(BuildContext context, Event event) {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "Xác nhận xóa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa sự kiện '${event.title}' không?",
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              "Hủy",
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () {
              Get.back(); // Đóng dialog xác nhận
            },
          ),
          TextButton(
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              Get.back(); // Đóng dialog xác nhận
              Get.back(); // Đóng dialog chi tiết sự kiện

              final EventServices eventServices = Get.find<EventServices>();
              final success = await eventServices.deleteEvent(event.id);

              if (success) {
                SnackbarUtils.showSuccess('Đã xóa sự kiện "${event.title}"');
              } else {
                SnackbarUtils.showError(
                    'Không thể xóa sự kiện "${event.title}"');
              }
            },
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }

  void _shareEvent(Event event) {
    final dateString = DateFormat('dd/MM/yyyy').format(event.eventDate);
    final shareContent = '${event.title}\n$dateString\n${event.description}';
    Share.share(shareContent);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color primaryTextColor =
        textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final Color secondaryTextColor =
        textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    const Color dayNumberColor = AppColors.primaryDark;
    const Color buttonTextColor = Color(0xFFD32F2F);
    final Color buttonBorderColor = buttonTextColor.withOpacity(0.8);

    final String normalizedEventType = event.eventType.trim().toLowerCase();
    final bool isUserEvent = normalizedEventType == EventTypeEnum.user_event.value;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD6D6D6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.r,
                        offset: Offset(0, 5.h),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.close,
                      size: 24.r,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ),
            ),

            // Số ngày lớn
            Text(
              event.eventDate.day.toString(),
              style: TextStyle(
                fontSize: 100.sp,
                fontWeight: FontWeight.bold,
                color: dayNumberColor,
                height: 1.0,
              ),
            ),
            SizedBox(height: 5.h),

            // Tháng và Năm
            Text(
              'Tháng ${event.eventDate.month} năm ${event.eventDate.year}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: primaryTextColor,
              ),
            ),
            SizedBox(height: 15.h),

            // Icon và Tiêu đề sự kiện
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: event.iconUrl ?? '',
                  width: 24.w,
                  height: 24.h,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.event, size: 24.w), // Icon dự phòng
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    event.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),

            // Đường kẻ trang trí
            Image.asset(
              IconsPath.lineCalendar,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 15.h),

            // Lời chúc/Sub-header sự kiện
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    event.wishes ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Mô tả sự kiện
            // Container(
            //   constraints: BoxConstraints(maxHeight: 150.h),
            //   child: SingleChildScrollView(
            //     child: Text(
            //       event.description.isNotEmpty
            //           ? event.description
            //           : (event.detail ?? 'Không có mô tả'),
            //       textAlign: TextAlign.center,
            //       style: TextStyle(
            //         fontSize: 16.sp,
            //         color: secondaryTextColor,
            //         height: 1.4,
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(height: 25.h),

            // --- PHẦN NÚT HÀNH ĐỘNG ---
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: [
                _buildActionButton(
                  context: context,
                  text: 'Xem chi tiết ngày',
                  icon: Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  onPressed: () {
                    Get.back();
                    Get.toNamed(
                      Routes.EVENT_DETAIL,
                      arguments: {'date': event.eventDate},
                    );
                  },
                ),
                _buildActionButton(
                  context: context,
                  text: 'Chia sẻ',
                  icon: Icons.share_outlined,
                  color: Colors.green,
                  onPressed: () {
                    _shareEvent(event);
                  },
                ),
                if (isUserEvent)
                  _buildActionButton(
                    context: context,
                    text: 'Sửa',
                    icon: Icons.edit_outlined,
                    color: Colors.blue,
                    onPressed: () {
                      Get.back();
                      Get.toNamed(
                        Routes.CREATE_NEW_EVENT,
                        arguments: {'event': event, 'isEdit': true},
                      );
                    },
                  ),
                _buildActionButton(
                  context: context,
                  text: 'Xóa',
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onPressed: () {
                    _showDeleteConfirmation(context, event);
                  },
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // --- KẾT THÚC PHẦN NÚT ---
          ],
        ),
      ),
    );
  }

  // Hàm helper để tạo các nút hành động
  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.sp),
      label: Text(text, style: TextStyle(fontSize: 16.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        elevation: 1, // Thêm đổ bóng nhẹ
      ),
    );
  }
}
// END REPLACE app/widgets/popup/event_detail_popup.dart
