import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
                  Image.asset(
                    'assets/icons/add_event.png',
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.contain,
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

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(
          16.w,
          16.h,
          16.w,
          16.h + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: SizedBox(
                width: 0.8.sw,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Get.back();
                      await controller.shareEvent(imageBytes: bytes);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Chia sẻ'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await controller.downloadCountdownImage(imageBytes: bytes);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Tải về'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}
