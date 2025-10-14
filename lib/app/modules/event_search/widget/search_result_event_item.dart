// File: app/modules/event_search/widget/search_result_event_item.dart
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:nhac_lich_viet/app/services/lunar_service.dart'; // Cần để lấy ngày âm
import 'package:nhac_lich_viet/app/theme/app_colors.dart'; // Dùng màu sắc nếu cần
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil
import 'package:intl/intl.dart'; // Để định dạng ngày dương
import 'package:nhac_lich_viet/app/utils/logger_utils.dart'; // Import LoggerUtils

/// Widget hiển thị một item kết quả tìm kiếm sự kiện.
///
/// Bao gồm tiêu đề sự kiện bên trái và cột ngày (dương lịch, âm lịch) bên phải.
class SearchResultEventItem extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap; // Callback khi người dùng nhấn vào item

  const SearchResultEventItem({
    super.key,
    required this.event,
    this.onTap,
  });

  // --- Các hàm helper để lấy và định dạng ngày ---
  String _getFormattedSolarDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date.toLocal());
  }

  String _getFormattedLunarDate(DateTime date) {
    try {
      final lunar = LunarService.getSolarToLunar(date.toLocal());
      return '${lunar.day.toString().padLeft(2, '0')}-${lunar.month} âm lịch';
    } catch (e) {
      LoggerUtils.error(
          "Lỗi chuyển đổi ngày âm trong SearchResultEventItem", e);
      return 'N/A âm lịch'; // Trả về giá trị dự phòng
    }
  }
  // --- Kết thúc hàm helper ---

  @override
  Widget build(BuildContext context) {
    // --- Định nghĩa Text Styles ---
    final titleStyle = TextStyle(
      fontSize: 19.sp, // Sử dụng ScreenUtil
      fontWeight: FontWeight.w500, // Đậm vừa
      color: AppColors.textPrimary,
    );
    final gregorianDateStyle = TextStyle(
      fontSize: 18.sp, // Sử dụng ScreenUtil
      color: AppColors.textSecondary, // Màu xám nhạt hơn
    );
    final lunarDateStyle = TextStyle(
      fontSize: 18.sp, // Sử dụng ScreenUtil
      color: AppColors.calendarLuckyDay, // Màu cam cho ngày âm
      // fontWeight: FontWeight.w500, // Có thể hơi đậm hơn nếu muốn
    );
    // --- ---

    // Lấy ngày dương và âm đã định dạng
    final String solarDateString = _getFormattedSolarDate(event.eventDate);
    final String lunarDateString = _getFormattedLunarDate(event.eventDate);

    // Khoảng cách padding cho item
    final double verticalPadding = 12.0.h; // Sử dụng ScreenUtil
    final double horizontalPadding =
        0; // Padding ngang sẽ được xử lý bởi ListView.separated

    return InkWell(
      // Cho phép tương tác khi nhấn vào
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Đẩy title và dates ra 2 bên
          crossAxisAlignment:
              CrossAxisAlignment.center, // Căn giữa theo chiều dọc
          children: [
            // Tiêu đề sự kiện (linh hoạt để không bị tràn nếu quá dài)
            Expanded(
              child: Text(
                event.title,
                style: titleStyle,
                overflow: TextOverflow.ellipsis, // Hiển thị '...' nếu quá dài
                maxLines: 2, // Giới hạn tối đa 2 dòng
              ),
            ),
            SizedBox(width: 16.w), // Khoảng cách giữa title và cột ngày

            // Cột chứa ngày dương lịch và âm lịch
            Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Căn phải các ngày
              mainAxisSize:
                  MainAxisSize.min, // Chỉ chiếm không gian dọc cần thiết
              children: [
                Text(
                  solarDateString,
                  style: gregorianDateStyle,
                ),
                SizedBox(height: 4.h), // Khoảng cách nhỏ giữa 2 ngày
                Text(
                  lunarDateString,
                  style: lunarDateStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
