// modules/profile_event/widgets/event_item_widget.dart
import 'package:nhac_lich_viet/app/services/lunar_service.dart';
import 'package:nhac_lich_viet/app/utils/date_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/modules/profile_event/controllers/profile_event_controller.dart';

class EventItemWidget extends StatelessWidget {
  final Event event;
  final String dateTime; // event.eventTime "HH:mm"
  final String remaining;
  final ProfileEventController controller;

  const EventItemWidget({
    Key? key,
    required this.event,
    required this.dateTime,
    required this.remaining,
    required this.controller,
  }) : super(key: key);

  String getLunarDateString(DateTime date) {
    try {
      final lunarDate = LunarService.getSolarToLunar(date.toLocal());
      return '${lunarDate.day.toString()}-${lunarDate.month} âm lịch';
    } catch (e) {
      return 'N/A âm lịch';
    }
  }

  @override
  Widget build(BuildContext context) {
    final solarDateString = DateTimeUtils.formatDMY(event.eventDate);
    final lunarDateString = getLunarDateString(event.eventDate);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Implement onTap event, maybe show event detail popup
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          // Row chính sẽ không còn nữa, toàn bộ là một Column
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HÀNG 1: Icon sự kiện, Tên sự kiện, và NÚT BA CHẤM ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Sự kiện
                  SizedBox(
                    width: 24.sp,
                    height: 24.sp,
                    child: (event.iconUrl != null &&
                            event.iconUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: event.iconUrl!,
                            fit: BoxFit.contain,
                            placeholder: (context, url) =>
                                Icon(Icons.image, size: 20.sp, color: Colors.grey),
                            errorWidget: (context, url, error) => Icon(
                                Icons.favorite,
                                size: 20.sp,
                                color: AppColors.error),
                          )
                        : Icon(Icons.event, size: 20.sp, color: Colors.grey),
                  ),
                  SizedBox(width: 8.w),
                  // Tên sự kiện (Expanded để chiếm không gian còn lại)
                  Expanded(
                    child: Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // SizedBox(width: 4.w), // Khoảng cách nhỏ trước nút ba chấm
                  // Nút Ba Chấm
                  SizedBox(
                    width: 28.r, // Điều chỉnh kích thước nếu cần
                    height: 28.r,
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: Colors.grey[600], size: 22.r),
                      padding: EdgeInsets.zero,
                      tooltip: 'Tùy chọn',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      offset: Offset(0, 35.h),
                      onSelected: (value) {
                        if (value == 'edit') {
                          controller.navigateToEditEvent(event);
                        } else if (value == 'delete') {
                          controller.showDeleteConfirmation(context, event);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined,
                                  color: AppColors.primary, size: 20.r),
                              SizedBox(width: 10.w),
                              Text(
                                'Sửa sự kiện',
                                style: TextStyle(
                                    fontSize: 18.sp, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20.r),
                              SizedBox(width: 10.w),
                              Text(
                                'Xoá sự kiện',
                                style: TextStyle(
                                    fontSize: 18.sp, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // --- HÀNG 2: Icon chuông, Thời gian (HH:mm) VÀ Ngày tạo sự kiện (dd-MM-yyyy) ---
              Row(
                children: [
                  Icon(Icons.notifications_none_outlined,
                      color: Colors.amber, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    dateTime, // event.eventTime "HH:mm"
                    style: TextStyle(fontSize: 18.sp, color: Color(0xFF616161)),
                  ),
                  const Spacer(),
                  Text(
                    solarDateString, // Ngày tạo sự kiện
                    style: TextStyle(fontSize: 18.sp, color: Color(0xFF616161)),
                  ),
                ],
              ),
              SizedBox(height: 6.h),

              // --- HÀNG 3: Icon đồng hồ, Số ngày còn lại VÀ Ngày âm lịch ---
              Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      color: Color(0xFFF05D07), size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    remaining,
                    style: TextStyle(fontSize: 18.sp, color: Colors.green),
                  ),
                  const Spacer(),
                  Text(
                    lunarDateString,
                    style: TextStyle(fontSize: 18.sp, color: Color(0xFFF05D07)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
