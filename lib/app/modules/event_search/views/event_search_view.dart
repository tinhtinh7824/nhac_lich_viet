// File: app/modules/event_search/views/event_search_view.dart

import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/widgets/optimized_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/event_search_controller.dart';
import '../../../theme/app_colors.dart';
import '../widget/search_result_event_item.dart';

class EventSearchView extends GetView<EventSearchController> {
  const EventSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F5925), Color(0xFF1FA259)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: controller.cancelSearch,
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back,
                                color: Colors.white, size: 22.sp),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Tìm kiếm sự kiện',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 18.w, vertical: 8.h),
                        child: Row(
                          children: [
                          Expanded(
                            child: Obx(
                              () => OptimizedSearchTextField(
                                controller: controller.searchController,
                                focusNode: controller.searchFocusNode,
                                hintText: 'Tìm kiếm sự kiện...',
                                showClearButton:
                                    controller.searchQuery.isNotEmpty,
                                onClear: controller.clearSearch,
                                onSubmitted: (value) =>
                                    controller.performSearch(value),
                                textStyle: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1B3B26),
                                ),
                                hintStyle: TextStyle(
                                  fontSize: 16.sp,
                                  color: const Color(0xFF88A093),
                                ),
                                cursorColor: const Color(0xFF1FA259),
                              ),
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF7F9F7),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }

                // Only show "no results" if we've finished searching (not debouncing)
                if (controller.searchQuery.isNotEmpty &&
                    !controller.hasResults.value &&
                    !controller.isDebouncing.value &&
                    controller.hasAttemptedSearch.value &&
                    controller.searchQuery.value ==
                        controller.lastSearchedQuery.value) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 16.h),
                        Text(
                          'Không tìm thấy kết quả phù hợp',
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Bạn hãy thử từ khóa khác hoặc xem ở phần sự kiện nhé!',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Show initial state or debouncing state
                if (controller.searchResults.isEmpty) {
                  // If debouncing, show previous results or loading hint
                  if (controller.isDebouncing.value &&
                      controller.searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50.w,
                            height: 50.h,
                            child: CircularProgressIndicator(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Đang tìm kiếm...',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Empty search query
                  if (controller.searchQuery.isEmpty) {
                    return Center(
                      child: Text(
                        'Nhập tên sự kiện để tìm kiếm.',
                        style:
                            TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                      ),
                    );
                  }
                }

                return ListView.separated(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                  itemCount: controller.searchResults.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: AppColors.divider.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final event = controller.searchResults[index];
                    return SearchResultEventItem(
                      event: event,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Get.toNamed(
                          Routes.EVENT_COUNTDOWN,
                          arguments: {'event': event},
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    ),
  );
  }
}
