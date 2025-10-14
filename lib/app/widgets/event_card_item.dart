// File: widgets/event_card_item.dart
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/services/lunar_service.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/utils/date_utils.dart'; // Changed import from utils.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventCardItem extends StatelessWidget {
  final String title;
  final DateTime eventDate;
  final String eventTime;
  final String icon;
  final Color iconColor; // Kept but not used in current implementation
  final VoidCallback? onTap;

  const EventCardItem({
    Key? key,
    required this.title,
    required this.eventDate,
    required this.eventTime,
    this.icon = '',
    this.iconColor = AppColors.error, // Default to AppColors.error
    this.onTap,
  }) : super(key: key);

  String getDaysRemainingText(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final difference = eventDay.difference(today).inDays;

    if (difference < 0) {
      final daysAgo = difference.abs();
      if (daysAgo == 1) return 'Hôm qua';
      if (daysAgo == 2) return '2 ngày trước';
      return '$daysAgo ngày trước';
    } else if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Ngày mai';
    } else if (difference == 2) {
      return '2 ngày nữa';
    } else {
      return '$difference ngày nữa';
    }
  }

  @override
  Widget build(BuildContext context) {
    LunarDate lunarDate = LunarService.getSolarToLunar(
      eventDate.toLocal(),
    );

    final dayLunar = lunarDate.day;
    final monthLunar = lunarDate.month;
    final lunarDateString = "$dayLunar-${monthLunar} âm lịch";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          right: 20.w, // Use .w
          left: 20.w,
          bottom: 16.h, // Use .h
          top: 11.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: icon,
                    width: 24.w, // Use .w
                    height: 24.h, // Use .h
                    fit: BoxFit.contain,
                    placeholder: (context, url) => SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary.withOpacity(0.5)))),
                    errorWidget: (context, url, error) => Icon(Icons.event,
                        size: 24.r, color: AppColors.textSecondary),
                  )
                else
                  Icon(Icons.event, size: 24.r, color: AppColors.textSecondary),
                SizedBox(width: 8.w), // Use .w
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18.sp, // Use .sp
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary, // Use AppColors
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w), // Use .w
                      Text(
                        DateTimeUtils.formatDMY(eventDate),
                        style: TextStyle(
                          fontSize: 18.sp, // Use .sp
                          color: AppColors.textSecondary, // Use AppColors
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h), // Use .h
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    getDaysRemainingText(eventDate.toLocal()),
                    style: TextStyle(
                      fontSize: 18.sp, // Use .sp
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(width: 8.w), // Use .w
                Text(
                  lunarDateString,
                  style: TextStyle(
                    color: AppColors.calendarLuckyDay, // Use AppColors
                    fontSize: 18.sp, // Use .sp
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  factory EventCardItem.fromEvent(Event event, {VoidCallback? onTap}) {
    return EventCardItem(
      title: event.title,
      eventDate: event.eventDate,
      eventTime: event.eventTime,
      icon: event.iconUrl ?? '',
      onTap: onTap,
    );
  }
}
