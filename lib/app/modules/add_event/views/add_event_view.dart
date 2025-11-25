import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/add_event_controller.dart';
import '../../../data/models/event_category_model.dart';

class AddEventView extends GetView<AddEventController> {
  const AddEventView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.7, 1.0],
                colors: [
                  Color(0xFF2E7D4E), // xanh lá đậm hơn
                  Color(0xFF4DBA6E), // xanh lá chính
                  Color(0xFF6BCF7F), // xanh lá nhạt
                ],
              ),
          ),
          child: AppBar(
            title: Text(
              'THÊM SỰ KIỆN MỚI',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, size: 28.sp),
              onPressed: () => Get.back(),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                mainAxisSpacing: 22.h,
                crossAxisSpacing: 20.w,
                physics: const BouncingScrollPhysics(),
                children: controller.categories.reversed.map((category) {
                  return _buildCategoryCard(category);
                }).toList(),
              ),
            ),
          ],
        );
      }),
      
    );
  }

  Widget _buildCategoryCard(EventCategory category) {
    return GestureDetector(
      onTap: () => controller.navigateToCreateEvent(category),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFF7FBF8), Color(0xFFE7F7EF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFDCEEE1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82.w,
              height: 82.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2AC769), Color(0xFF1FA259)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1FA259).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: (category.iconUrl != null && category.iconUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: category.iconUrl!,
                        width: 82.w,
                        height: 82.w,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Icon(
                          Icons.event,
                          size: 42.w,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.event,
                          size: 42.w,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : Icon(
                        Icons.event,
                        size: 42.w,
                        color: Colors.white,
                      ),
              ),
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text(
                category.title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D3F2A),
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
