// File: modules/lt_sk/view/widgets/event_list_item.dart
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/services/lunar_service.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class EventListItem extends StatelessWidget {
  final Event event;
  final String remainingDaysText;
  final Color statusColor;
  final int typeIndicator; // -1 for past, 1 for current/future
  final VoidCallback? onTap;
  final VoidCallback?
      onView; // Giữ lại để không phá vỡ API, dù không dùng trực tiếp
  final VoidCallback?
      onEdit; // Giữ lại để không phá vỡ API, dù không dùng trực tiếp
  final VoidCallback?
      onDelete; // Giữ lại để không phá vỡ API, dù không dùng trực tiếp

  const EventListItem({
    Key? key,
    required this.event,
    required this.remainingDaysText,
    required this.statusColor,
    required this.typeIndicator,
    this.onTap,
    this.onView,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  String getLunarDateString(DateTime date) {
    try {
      final lunarDate = LunarService.getSolarToLunar(date);
      return '${lunarDate.day.toString().padLeft(2, '0')}-${lunarDate.month} âm lịch';
    } catch (e) {
      return '';
    }
  }

  String getSolarDateString(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final lunarDateString = getLunarDateString(event.eventDate);
    final solarDateString = getSolarDateString(event.eventDate);

    return Column(
      children: [
        InkWell(
          onTap: onTap, // Sử dụng onTap được truyền vào
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Title và Solar Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: typeIndicator == -1
                              ? Color(
                                  0xFF616161) // Màu title cho sự kiện quá khứ
                              : AppColors
                                  .textPrimary, // Màu title cho sự kiện hiện tại/tương lai
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      solarDateString,
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF616161) // Màu ngày dương lịch
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),

                // Row 2: Remaining Days và Lunar Date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        remainingDaysText,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color:
                              statusColor, // Màu cho remainingDaysText (từ controller)
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      lunarDateString,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: typeIndicator == 1
                            ? AppColors
                                .calendarLuckyDay // Màu ngày âm cho sự kiện hiện tại/tương lai
                            : Color(
                                0xFF616161), // Màu ngày âm cho sự kiện quá khứ
                      ),
                    ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
        Divider(
          height: 1.h,
          thickness: 1.h,
          color: AppColors.divider,
        ),
      ],
    );
  }
}
