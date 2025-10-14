// File: app/widgets/event_card_item_placeholder.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart'; // Cần để lấy màu placeholder

class EventCardItemPlaceholder extends StatelessWidget {
  const EventCardItemPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Màu sắc cho hiệu ứng shimmer
    final baseColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.white, // Placeholder background
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.divider.withOpacity(0.5)), // Placeholder border
        ),
        child: Row(
          children: [
            // Cột Trái Placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder cho title
                  Container(
                    width: double.infinity, // Chiếm hết chiều ngang
                    height: 18.h, // Chiều cao tương đương title
                    decoration: BoxDecoration(
                      color: Colors.white, // Màu nền của placeholder shape
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Placeholder cho remaining days
                  Container(
                    width: 100.w, // Chiều rộng cố định
                    height: 14.h, // Chiều cao tương đương remaining days
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Cột Phải Placeholder
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Placeholder cho ngày dương lịch
                Container(
                  width: 80.w, // Chiều rộng cố định
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                // Placeholder cho ngày âm lịch
                Container(
                  width: 100.w, // Chiều rộng cố định
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}