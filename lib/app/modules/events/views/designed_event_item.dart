// lib/app/modules/events/views/widgets/designed_event_item.dart
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/modules/detail/services/lunar_service.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:nhac_lich_viet/app/modules/events/controllers/events_controller.dart';

class DesignedEventItem extends StatelessWidget {
  final Event event;
  final String remainingDaysText; // Nhận chuỗi đã tính toán
  final Color statusColor; // Nhận màu trạng thái
  final int type;

  const DesignedEventItem({
    Key? key,
    required this.event,
    required this.remainingDaysText,
    required this.statusColor,
    this.type = 0, // Mặc định là 0
  }) : super(key: key);

  // Hàm lấy ngày âm lịch từ controller hoặc service
  String getLunarDateString(DateTime date) {
    try {
      final lunarDate = LunarService.getSolarToLunar(date);
      // Định dạng dd-M âm lịch
      return '${lunarDate.day.toString().padLeft(2, '0')}-${lunarDate.month} âm lịch';
    } catch (e) {
      // Xử lý lỗi nếu không chuyển đổi được
      LoggerUtils.error('Error converting to Lunar date', e);
      return ''; // Trả về chuỗi rỗng hoặc thông báo lỗi
    }
  }

  // Hàm định dạng ngày dương lịch dd-MM-yyyy
  String getSolarDateString(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  // Helper method để lấy text hiển thị cho countdown
  String _getCountdownDisplayText(String remainingDaysText) {
    if (remainingDaysText == 'Hôm nay') {
      return 'Hôm nay';
    } else if (remainingDaysText == 'Ngày mai') {
      return 'Ngày mai';
    } else {
      // Trích xuất số từ text như "5 ngày nữa" → "5"
      return remainingDaysText.replaceAll(' ngày nữa', '').replaceAll(' ngày trước', '');
    }
  }

  // Helper method để kiểm tra text đặc biệt (không cần chữ "ngày")
  bool _isSpecialText(String remainingDaysText) {
    return remainingDaysText == 'Hôm nay' || remainingDaysText == 'Ngày mai';
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color backgroundColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SizedBox(
        width: 70.w,
        child: Container(
          height: 70.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20.sp),
              SizedBox(height: 6.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _showEventPopup(BuildContext context) {
  //   Get.dialog(
  //     EventDetailPopup(event: event),
  //     barrierDismissible: true, // Cho phép đóng khi chạm ra ngoài
  //     barrierColor: Colors.black.withOpacity(0.6), // Màu nền mờ
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final lunarDateString = getLunarDateString(event.eventDate);
    final solarDateString = getSolarDateString(event.eventDate);
    final isUserEvent =
        event.eventType.trim().toLowerCase() == EventTypeEnum.user_event.value;

    if (type == 0) {
      return GestureDetector(
        onTap: () {
          Get.toNamed(Routes.EVENT_COUNTDOWN, arguments: {'event': event});
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (event.iconUrl != null && event.iconUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: event.iconUrl!,
                  width: 36.w,
                  height: 36.h,
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) => Icon(Icons.event,
                      size: 36.r, color: AppColors.textSecondary),
                )
              else
                Icon(Icons.event, size: 36.r, color: AppColors.textSecondary),
              SizedBox(width: 8.w), // Khoảng cách giữa icon và text
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF616161),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // --- Phần type != 0 được chỉnh sửa thành button style ---
    return Slidable(
      key: ValueKey(event.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (isUserEvent)
            CustomSlidableAction(
              onPressed: (context) => _onEdit(),
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: _buildActionButton(
                icon: Icons.edit,
                iconColor: const Color(0xFF4C7DFF),
                label: 'Sửa',
                backgroundColor: const Color(0xFFE8EEFF),
              ),
            ),
          CustomSlidableAction(
            onPressed: (context) => _onShare(),
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: _buildActionButton(
              icon: Icons.share,
              iconColor: const Color(0xFF3CBC77),
              label: 'Chia sẻ',
              backgroundColor: const Color(0xFFE8F8F1),
            ),
          ),
          CustomSlidableAction(
            onPressed: (context) => _onDelete(context),
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: _buildActionButton(
              icon: Icons.delete_outline,
              iconColor: const Color(0xFFE86666),
              label: 'Xóa',
              backgroundColor: const Color(0xFFFFEFEF),
            ),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Get.toNamed(Routes.EVENT_COUNTDOWN, arguments: {'event': event});
            },
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Cột 1: Tên sự kiện và ngày tháng
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dòng 1: Tên sự kiện
                        Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: type == -1
                                ? Color(0xFF616161)
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        // Dòng 2: Lịch dương (lịch âm) - âm lịch và ngoặc màu đỏ
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$solarDateString ',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF616161),
                                ),
                              ),
                              TextSpan(
                                text: '($lunarDateString)',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // Cột 2: Số ngày đếm ngược
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Dòng 1: Số ngày hoặc text đặc biệt
                      Text(
                        _getCountdownDisplayText(remainingDaysText),
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      // Dòng 2: Chữ "ngày" (chỉ hiển thị nếu không phải text đặc biệt)
                      if (!_isSpecialText(remainingDaysText))
                        Text(
                          'ngày',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF616161),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Action methods for slidable
  void _onEdit() {
    var eventToEdit = event;

    if (event.isOccurrence && event.originalEventId != null) {
      try {
        final originalEvent =
            Get.find<EventServices>().getEventById(event.originalEventId!);
        if (originalEvent != null) {
          eventToEdit = originalEvent;
        } else {
          LoggerUtils.warning(
              'Original event not found for occurrence: ${event.originalEventId}');
        }
      } catch (e) {
        LoggerUtils.warning('EventServices not available for edit: $e');
      }
    }

    // Điều hướng tới màn hình chỉnh sửa với dữ liệu sự kiện hiện có
    Get.toNamed(
      Routes.CREATE_NEW_EVENT,
      arguments: {'event': eventToEdit.copyWith(), 'isEdit': true},
    );
  }

  void _onShare() {
    final lunarDateString = getLunarDateString(event.eventDate);
    final solarDateString = getSolarDateString(event.eventDate);

    final shareText = '''
🎉 ${event.title}

📅 Ngày: $solarDateString
🌙 Âm lịch: $lunarDateString

Được chia sẻ từ ứng dụng Nhắc lịch Việt
''';

    Share.share(shareText);
  }

  void _onDelete(BuildContext context) {
    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        title: Text(
          'Xác nhận xóa',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa sự kiện này?',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              event.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Hủy',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implement delete event functionality
              _deleteEvent();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Xóa',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent() async {
    var eventToDelete = event;

    try {
      final eventServices = Get.find<EventServices>();
      if (event.isOccurrence && event.originalEventId != null) {
        final original =
            eventServices.getEventById(event.originalEventId!);
        if (original != null) {
          eventToDelete = original;
        } else {
          LoggerUtils.warning(
              'Original event not found when deleting occurrence: ${event.originalEventId}');
        }
      }

      final success = await eventServices.deleteEvent(eventToDelete.id);
      if (success) {
        try {
          Get.find<EventsController>().removeEventById(eventToDelete.id);
        } catch (e) {
          LoggerUtils.warning('EventsController not available to remove event: $e');
        }
        SnackbarUtils.showSuccess('Đã xóa sự kiện "${eventToDelete.title}"');
      } else {
        SnackbarUtils.showError('Không thể xóa sự kiện. Vui lòng thử lại.');
      }
    } catch (e) {
      LoggerUtils.error('Error deleting event ${event.id}', e);
      SnackbarUtils.showError('Không thể xóa sự kiện. Vui lòng thử lại.');
    }
  }
}
