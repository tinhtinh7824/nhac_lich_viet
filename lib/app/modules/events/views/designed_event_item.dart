// lib/app/modules/events/views/widgets/designed_event_item.dart
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/modules/detail/services/lunar_service.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/services/event_services.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:nhac_lich_viet/app/widgets/shared_buttons/share_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:nhac_lich_viet/app/modules/events/controllers/events_controller.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';

class DesignedEventItem extends StatefulWidget {
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

  @override
  State<DesignedEventItem> createState() => _DesignedEventItemState();
}

class _DesignedEventItemState extends State<DesignedEventItem> {
  final GlobalKey _captureKey = GlobalKey();
  final RxBool _showShareLayer = false.obs;

  Event get event => widget.event;
  String get remainingDaysText => widget.remainingDaysText;
  Color get statusColor => widget.statusColor;
  int get type => widget.type;

  @override
  void initState() {
    super.initState();
    // Preload background image ngay khi widget được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final backgroundPath = _pickBackgroundFor(event);
        precacheImage(AssetImage(backgroundPath), context);
      }
    });
  }

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

  // Calculate detailed countdown for sharing image
  Map<String, dynamic> _calculateDetailedCountdown() {
    final now = DateTime.now();
    final eventDateTime = event.eventDate;
    final difference = eventDateTime.difference(now);

    if (difference.isNegative) {
      // Event has passed or is today
      final isToday = eventDateTime.year == now.year &&
                     eventDateTime.month == now.month &&
                     eventDateTime.day == now.day;
      return {
        'isOngoing': isToday,
        'days': 0,
        'hours': 0,
        'minutes': 0,
        'seconds': 0,
      };
    }

    return {
      'isOngoing': false,
      'days': difference.inDays,
      'hours': difference.inHours % 24,
      'minutes': difference.inMinutes % 60,
      'seconds': difference.inSeconds % 60,
    };
  }

  String _getVietnameseDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ Hai';
      case 2: return 'Thứ Ba';
      case 3: return 'Thứ Tư';
      case 4: return 'Thứ Năm';
      case 5: return 'Thứ Sáu';
      case 6: return 'Thứ Bảy';
      case 7: return 'Chủ Nhật';
      default: return '';
    }
  }

  String _pickBackgroundFor(Event event) {
    final normalizedTitle = event.title.trim().toLowerCase();

    if (normalizedTitle == 'ngày phụ nữ việt nam' || normalizedTitle == 'ngày quốc tế phụ nữ') {
      return 'assets/images/events_background_countdown_20-10.jpg';
    }
    if (normalizedTitle == 'ngày halloween') {
      return 'assets/images/events_background_countdown_31-10.jpg';
    }
    if (normalizedTitle == 'ngày nhà giáo việt nam') {
      return 'assets/images/events_background_countdown_20-11.png';
    }
    if (normalizedTitle == 'ngày lễ giáng sinh') {
      return 'assets/images/events_background_countdown_25-12.jpg';
    }
    if (normalizedTitle == 'tết dương lịch' || normalizedTitle == 'tết nguyên đán (tết âm lịch)' || normalizedTitle == 'mùng hai tết' || normalizedTitle == 'mùng ba tết') {
      return 'assets/images/events_background_countdown_tet.jpg';
    }
    if (normalizedTitle == 'tết trung thu, rằm tháng 8 âm lịch') {
      return 'assets/images/events_background_countdown_15-8.jpg';
    }

    // Default background
    return 'assets/images/events_background_countdown.jpg';
  }

  // Tạo shareable widget giống countdown view với tỷ lệ 9:16
  Widget _buildShareableEventCard() {
    return AspectRatio(
      aspectRatio: 9.0 / 16.0, // Tỷ lệ 9:16 chính xác
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_pickBackgroundFor(event)),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: _buildCountdownContent(),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nhắc lịch Việt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.85),
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownContent() {
    final countdownData = _calculateDetailedCountdown();
    final dayName = _getVietnameseDayName(event.eventDate.weekday);
    final lunarDateString = getLunarDateString(event.eventDate);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Event title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            event.title,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 40.h),

        // Countdown or ongoing message
        if (countdownData['isOngoing'])
          Column(
            children: [
              Text(
                'Sự kiện đang diễn ra hôm nay!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Chúc bạn có những khoảnh khắc ý nghĩa.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
            ],
          )
        else
          Column(
            children: [
              _buildCountdownMetrics(countdownData),
              SizedBox(height: 32.h),
            ],
          ),

        // Date info
        _buildDateInfo(dayName, lunarDateString),
      ],
    );
  }

  Widget _buildCountdownMetrics(Map<String, dynamic> countdownData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              '${countdownData['days']}',
              style: TextStyle(
                fontSize: 96.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 0.8,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'NGÀY',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        SizedBox(width: 18.w),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8.w,
              height: 8.w,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              width: 8.w,
              height: 8.w,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        SizedBox(width: 18.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSmallCountdownItem(countdownData['hours'], 'GIỜ'),
            SizedBox(height: 12.h),
            _buildSmallCountdownItem(countdownData['minutes'], 'PHÚT'),
            SizedBox(height: 12.h),
            _buildSmallCountdownItem(countdownData['seconds'], 'GIÂY'),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallCountdownItem(int value, String label) {
    return SizedBox(
      width: 140.w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 42.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String dayName, String lunarDateString) {
    return Column(
      children: [
        Text(
          '$dayName - ${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Text(
          '($lunarDateString)',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.red[800],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Capture widget as image
  Future<Uint8List?> _captureEventImage() async {
    _showShareLayer.value = true;
    try {
      // Đảm bảo background image đã được preload
      final backgroundPath = _pickBackgroundFor(event);
      await precacheImage(AssetImage(backgroundPath), context);

      // Đợi widget render với background
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300)); // Đợi lâu hơn để đảm bảo

      RenderRepaintBoundary? boundary =
          _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      for (int retry = 0; retry < 15; retry++) {
        if (boundary != null && !boundary.debugNeedsPaint) {
          break;
        }
        await WidgetsBinding.instance.endOfFrame;
        await Future.delayed(const Duration(milliseconds: 100));
        boundary =
            _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      }

      if (boundary == null || boundary.debugNeedsPaint) {
        LoggerUtils.warning(
            'captureEventImage boundary not ready (debugNeedsPaint=${boundary?.debugNeedsPaint}).');
        return null;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      return bytes;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error capturing event image', e, stackTrace);
      return null;
    } finally {
      _showShareLayer.value = false;
    }
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
    return Stack(
      children: [
        // Share layer (invisible)
        Obx(
          () => _showShareLayer.value
              ? IgnorePointer(
                  ignoring: true,
                  child: Opacity(
                    opacity: 0.01,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: _buildShareableEventCard(),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Main UI
        Slidable(
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
                  iconColor: const Color(0xFF00A86B),
                  label: 'Chia sẻ',
                  backgroundColor: const Color(0xFFE8F5E8),
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
        ),
      ],
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

  Future<void> _onShare() async {
    try {
      // Capture widget as image
      final imageBytes = await _captureEventImage();
      if (imageBytes == null) {
        SnackbarUtils.showError('Không thể chuẩn bị nội dung chia sẻ.');
        return;
      }

      // Hiển thị ShareBottomSheet với ảnh preview
      ShareBottomSheet.show(
        imageBytes: imageBytes,
        onShare: () async {
          await _shareEventImage(imageBytes);
        },
        onDownload: () async {
          await _downloadEventImage(imageBytes);
        },
      );
    } catch (e) {
      LoggerUtils.error('Error creating/sharing event image', e);
      SnackbarUtils.showError('Không thể tạo ảnh chia sẻ. Vui lòng thử lại.');

      // Fallback to text sharing
      _shareEventText(); 
    }
  }

  Future<void> _shareEventImage(Uint8List imageBytes) async {
    try {
      // Lưu ảnh tạm thời và chia sẻ
      final now = DateTime.now().millisecondsSinceEpoch;
      await Share.shareXFiles([
        XFile.fromData(
          imageBytes,
          name: 'event_${event.id}_$now.png',
          mimeType: 'image/png',
        ),
      ], text: '🎉 ${event.title}\n\nĐược chia sẻ từ ứng dụng Nhắc lịch Việt');
    } catch (e) {
      LoggerUtils.error('Error sharing event image', e);
      SnackbarUtils.showError('Không thể chia sẻ ảnh. Vui lòng thử lại.');
    }
  }

  Future<void> _downloadEventImage(Uint8List imageBytes) async {
    try {
      // Yêu cầu quyền truy cập storage
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          SnackbarUtils.showError('Cần quyền truy cập ảnh để lưu file.');
          return;
        }
      }

      // Lưu ảnh vào thư viện ảnh sử dụng gal package
      await Gal.putImageBytes(imageBytes);

      SnackbarUtils.showSuccess('Đã lưu ảnh vào thư viện ảnh');
      Get.back(); // Đóng bottom sheet
    } catch (e) {
      LoggerUtils.error('Error downloading event image', e);
      SnackbarUtils.showError('Không thể lưu ảnh. Vui lòng thử lại.');
    }
  }

  void _shareEventText() {
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
