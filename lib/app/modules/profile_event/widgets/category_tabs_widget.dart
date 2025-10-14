import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart'; // *** THÊM IMPORT GET ***
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/modules/profile_event/controllers/profile_event_controller.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart'; // Thêm LoggerUtils nếu cần debug

class CategoryTabsWidget extends StatelessWidget {
  final ProfileEventController controller;

  const CategoryTabsWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // *** BỌC PHẦN HIỂN THỊ TAB BẰNG Obx ***
    return Obx(() {
      // Di chuyển logic tạo list vào bên trong Obx
      final List<Map<String, String>> categoryList = [
        {'title': 'Tất cả', 'id': 'all'}, // Luôn có tab "Tất cả"
        ...controller.eventCategories
            .map((cat) => {'title': cat.title, 'id': cat.id})
            .toList()
            .reversed,
      ];

      // Log để kiểm tra (có thể bỏ đi sau khi xác nhận)
      LoggerUtils.debug(
          "CategoryTabsWidget building with ${categoryList.length} tabs.");

      // Chỉ hiển thị nếu có nhiều hơn 1 tab ("Tất cả" + ít nhất 1 category khác)
      // Hoặc luôn hiển thị nếu bạn muốn thấy "Tất cả" ngay cả khi không có category nào khác
      if (categoryList.length <= 1 && controller.events.isEmpty) {
        // Hoặc có thể trả về SizedBox.shrink() nếu không muốn hiển thị gì cả
        return SizedBox(height: 50.h); // Giữ chiều cao để layout không bị nhảy
      }

      return Container(
        height: 50.h, // Giữ chiều cao cố định
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categoryList.length,
                itemBuilder: (context, index) {
                  final category = categoryList[index];
                  // Lấy selectedTabIndex từ controller trong Obx
                  final isSelected = controller.selectedTabIndex.value == index;

                  return GestureDetector(
                    onTap: () {
                      controller.selectCategory(category['title']!, index);
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category['title']!,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
            Divider(
              height: 1.h,
              color: Colors.grey[300],
            ),
          ],
        ),
      );
    }); // *** KẾT THÚC Obx ***
  }
}
