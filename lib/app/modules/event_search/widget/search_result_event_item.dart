// File: app/modules/event_search/widget/search_result_event_item.dart
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/services/lunar_service.dart'; // Cần để lấy ngày âm
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import 'package:intl/intl.dart'; // Để định dạng ngày dương
import 'package:nhac_lich_viet/app/utils/logger_utils.dart'; // Import LoggerUtils

/// Widget hiển thị một item kết quả tìm kiếm sự kiện đơn giản.
///
/// Bao gồm tiêu đề sự kiện, ngày tháng và số ngày còn lại.
class SearchResultEventItem extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap; // Callback khi người dùng nhấn vào item

  const SearchResultEventItem({
    super.key,
    required this.event,
    this.onTap,
  });

  // --- Các hàm helper để lấy và định dạng ngày ---
  String _getFormattedSolarDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date.toLocal());
  }

  String _getFormattedLunarDate(DateTime date) {
    try {
      final lunar = LunarService.getSolarToLunar(date.toLocal());
      return '${lunar.day.toString().padLeft(2, '0')}-${lunar.month} âm lịch';
    } catch (e) {
      LoggerUtils.error(
          "Lỗi chuyển đổi ngày âm trong SearchResultEventItem", e);
      return 'N/A âm lịch'; // Trả về giá trị dự phòng
    }
  }

  // Helper để tính số ngày còn lại
  int _getDaysUntilEvent() {
    final now = DateTime.now();
    final difference = event.eventDate.difference(now).inDays;
    return difference;
  }

  // --- Kết thúc hàm helper ---

  @override
  Widget build(BuildContext context) {
    // Lấy ngày dương và âm đã định dạng
    final String solarDateString = _getFormattedSolarDate(event.eventDate);
    final String lunarDateString = _getFormattedLunarDate(event.eventDate);
    final int daysUntil = _getDaysUntilEvent();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Nội dung bên trái
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề sự kiện
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 6.h),

                      // Ngày dương lịch và âm lịch
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: solarDateString,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF6B7280),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            TextSpan(
                              text: ' ($lunarDateString)',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Số ngày còn lại bên phải
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      daysUntil.abs().toString(),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: daysUntil >= 0
                            ? const Color(0xFF059669)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      'ngày',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
