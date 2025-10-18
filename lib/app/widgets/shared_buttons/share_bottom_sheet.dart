import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Shared bottom sheet for sharing content consistently across the app
class ShareBottomSheet {
  /// Shows the share bottom sheet with preview image and action buttons
  static Future<void> show({
    required Uint8List imageBytes,
    required VoidCallback onShare,
    required VoidCallback onDownload,
  }) async {
    final context = Get.context;
    if (context == null) return;

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
                    imageBytes,
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
                      onShare();
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
                      onDownload();
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