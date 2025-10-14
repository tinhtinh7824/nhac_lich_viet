import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/modules/daily_event_popup/controllers/daily_event_popup_controller.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class DailyEventPopupView extends GetView<DailyEventPopupController> {
  final Event event;

  const DailyEventPopupView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Determine content to show based on eventType
    String? contentToShow;
    if (event.eventType == EventTypeEnum.system_event.value) {
      if (event.wishes != null && event.wishes!.isNotEmpty) {
        contentToShow = event.wishes;
      }
    } else if (event.eventType == EventTypeEnum.user_event.value) {
      if (event.description.isNotEmpty) {
        contentToShow = event.description;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 0.8.sh,
          maxWidth: 380.w,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24.r,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // Main content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Space for close button
                            SizedBox(height: 24.h),

                            // Event icon
                            // if (event.iconUrl != null && event.iconUrl!.isNotEmpty)
                            //   Container(
                            //     margin: EdgeInsets.only(bottom: 16.h),
                            //     child: CachedNetworkImage(
                            //       imageUrl: event.iconUrl!,
                            //       width: 64.r,
                            //       height: 64.r,
                            //       fit: BoxFit.contain,
                            //       placeholder: (context, url) => SizedBox(
                            //         width: 64.r,
                            //         height: 64.r,
                            //         child: CircularProgressIndicator(
                            //           strokeWidth: 2,
                            //           color: AppColors.primary.withValues(alpha: 0.3),
                            //         ),
                            //       ),
                            //       errorWidget: (context, url, error) => Container(
                            //         width: 64.r,
                            //         height: 64.r,
                            //         decoration: BoxDecoration(
                            //           color: AppColors.primary.withValues(alpha: 0.08),
                            //           shape: BoxShape.circle,
                            //         ),
                            //         child: Icon(
                            //           Icons.event_note_rounded,
                            //           color: AppColors.primary,
                            //           size: 36.sp,
                            //         ),
                            //       ),
                            //     ),
                            //   ),

                            // Title
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            // Subtitle
                            if (event.subtitle != null &&
                                event.subtitle!.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                event.subtitle!,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],

                            // Banner image
                            if (event.bannerUrl != null &&
                                event.bannerUrl!.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: CachedNetworkImage(
                                  imageUrl: event.bannerUrl!,
                                  width: double.infinity,
                                  height: 160.h,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 160.h,
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.5),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    height: 200.h,
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey[400],
                                      size: 48.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Content/Wishes
                            if (contentToShow != null) ...[
                              SizedBox(height: 12.h),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: MarkdownBody(
                                  data: contentToShow,
                                  styleSheet: MarkdownStyleSheet(
                                    h1: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                    h2: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                    h3: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                    p: TextStyle(
                                      fontSize: 16.sp,
                                      color: AppColors.textPrimary,
                                      height: 1.5,
                                      letterSpacing: 0.2,
                                    ),
                                    listBullet: TextStyle(
                                      fontSize: 16.sp,
                                      color: AppColors.textPrimary,
                                      height: 1.5,
                                    ),
                                    listIndent: 20.w,
                                    a: TextStyle(
                                      fontSize: 16.sp,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    blockquote: TextStyle(
                                      fontSize: 16.sp,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    code: TextStyle(
                                      fontSize: 14.sp,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      fontFamily: 'monospace',
                                    ),
                                    // horizontalRuleDecoration: BoxDecoration(
                                    //   border: Border(
                                    //     bottom: BorderSide(
                                    //       color: AppColors.textSecondary
                                    //           .withValues(alpha: 0.3),
                                    //       width: 1,
                                    //     ),
                                    //   ),
                                    // ),
                                    // blockSpacing: 8.h,
                                    // pPadding:
                                    //     EdgeInsets.symmetric(vertical: 2.h),
                                  ),
                                  shrinkWrap: true,
                                  softLineBreak: true,
                                  selectable: false,
                                ),
                              ),
                            ],

                            // Xem thêm button
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: double.infinity,
                              height: 44.h,
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.back();
                                  controller.handlePopupAction(event, true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 0),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Xem chi tiết',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          height: 1.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 22.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Floating close button
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        controller.handlePopupAction(event, false);
                      },
                      borderRadius: BorderRadius.circular(20.r),
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 24.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
