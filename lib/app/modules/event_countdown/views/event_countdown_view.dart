import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nhac_lich_viet/app/widgets/shared_buttons/share_bottom_sheet.dart';

import '../controllers/event_countdown_controller.dart';
import '../../../utils/snackbar_utils.dart';

class EventCountdownView extends GetView<EventCountdownController> {
  const EventCountdownView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(controller.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopActions(context),
              Expanded(
                child: Stack(
                  children: [
                    Obx(
                      () => controller.showShareLayer.value
                          ? IgnorePointer(
                              ignoring: true,
                              child: Opacity(
                                opacity: 0.01,
                                child: RepaintBoundary(
                                  key: controller.captureKey,
                                  child: _buildShareableCountdownCard(),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Center(child: _buildCountdownContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Icon(
              Icons.arrow_back,
              color: Colors.black,
              size: 28.sp,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showShareOptions(context),
                child: Icon(
                  Icons.share,
                  color: Colors.black,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 20.w),
              Obx(
                () => Visibility(
                  visible: controller.canEdit.value,
                  child: GestureDetector(
                    onTap: controller.editEvent,
                    child: Icon(
                      Icons.edit,
                      color: Colors.black,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Obx(
            () => Text(
              controller.eventTitle.value,
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 40.h),
        Obx(
          () {
            if (controller.isEventOngoing.value) {
              return Column(
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
              );
            }

            return Column(
              children: [
                _buildCountdownMetrics(),
                SizedBox(height: 32.h),
              ],
            );
          },
        ),
        _buildDateInfo(),
        SizedBox(height: 78.h),
      ],
      
    );
  }

  Widget _buildCountdownMetrics() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Obx(
              () => Text(
                '${controller.remainingDays.value}',
                style: TextStyle(
                  fontSize: 96.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 0.8,
                ),
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
            _buildSmallCountdownItem(
              value: controller.remainingHours,
              label: 'GIỜ',
            ),
            SizedBox(height: 12.h),
            _buildSmallCountdownItem(
              value: controller.remainingMinutes,
              label: 'PHÚT',
            ),
            SizedBox(height: 12.h),
            _buildSmallCountdownItem(
              value: controller.remainingSeconds,
              label: 'GIÂY',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateInfo() {
    return Column(
      children: [
        Obx(
          () => Text(
            '${controller.dayName.value} - ${controller.eventDate.value.day}/${controller.eventDate.value.month}/${controller.eventDate.value.year}',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 4.h),
        Obx(
          () => Text(
            '(${controller.lunarDate.value})',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.red[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildShareableCountdownCard() {
    final BuildContext? ctx = Get.context;
    final screenSize = ctx != null
        ? MediaQuery.of(ctx).size
        : Size(ScreenUtil().screenWidth, ScreenUtil().screenHeight);

    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(controller.backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
                child: _buildCountdownContent(),
              ),
            ),
            Positioned(
              bottom: 24.h,
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
                  SizedBox(width: 8.w),
                  Text(
                    'Nhắc lịch Việt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color.fromARGB(255, 0, 0, 0)
                          .withValues(alpha: 0.85),
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
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

  Widget _buildSmallCountdownItem({
    required RxInt value,
    required String label,
  }) {
    return SizedBox(
      width: 140.w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Obx(
              () => Text(
                '${value.value}',
                style: TextStyle(
                  fontSize: 42.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.right,
              ),
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

  Future<void> _showShareOptions(BuildContext context) async {
    final Uint8List? bytes = await controller.captureCountdownImage();
    if (bytes == null) {
      SnackbarUtils.showError('Không thể chuẩn bị nội dung chia sẻ.');
      return;
    }

    ShareBottomSheet.show(
      imageBytes: bytes,
      onShare: () => controller.shareEvent(imageBytes: bytes),
      onDownload: () => controller.downloadCountdownImage(imageBytes: bytes),
    );
  }
}
