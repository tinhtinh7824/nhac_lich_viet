// File: app/modules/home/views/widgets/upcoming_events_widget.dart
import 'package:nhac_lich_viet/app/modules/events/controllers/events_controller.dart';
import 'package:nhac_lich_viet/app/widgets/event_card_item.dart';
import 'package:nhac_lich_viet/app/widgets/event_card_item_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Import ScreenUtil

class UpcomingEventsWidget extends StatefulWidget {
  const UpcomingEventsWidget({Key? key}) : super(key: key);

  @override
  State<UpcomingEventsWidget> createState() => _UpcomingEventsWidgetState();
}

class _UpcomingEventsWidgetState extends State<UpcomingEventsWidget> {
  // Lấy instance của EventsController
  // Dùng Get.find() vì EventsBinding đã được gọi trong MainHomeBinding
  late final EventsController eventsController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<EventsController>()) {
      eventsController = Get.find<EventsController>();
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<EventsController>()) {
      return const Center(child: Text("Lỗi: Controller chưa sẵn sàng."));
    }

    return Obx(() {
      final isLoading = eventsController.isLoading.value;
      final upcomingEvents = eventsController.allUpcomingEvents;
      final bool hasData = upcomingEvents.isNotEmpty;

      // Chỉ hiển thị shimmer khi loading và hoàn toàn không có dữ liệu từ cache
      if (isLoading && !hasData) {
        return _buildShimmerLoading();
      }
      // Nếu có dữ liệu (cache hoặc từ API), hiển thị ngay
      else if (hasData) {
        final limitedEvents = upcomingEvents.take(3).toList();

        return Container(
          margin: EdgeInsets.only(bottom: 4.h),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r), // Use .r
              border: Border.all(
                color: const Color(0xFFD6FFC5AC), // Keep specific or map
                width: 1.w, // Use .w
              ),
              color: const Color(0xFFFDF7EB)), // Keep specific or map
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(limitedEvents.length, (index) {
              final event = limitedEvents[index];
              // Kiểm tra xem đây có phải là event cuối cùng không
              final bool isLastEvent = index == limitedEvents.length - 1;
              return Column(
                children: [
                  EventCardItem.fromEvent(
                    event,
                    onTap: () {
                      eventsController.goToEventDetail(event.eventDate,
                          event: event);
                    },
                  ),
                  if (!isLastEvent)
                    Column(
                      children: [
                        SizedBox(
                          height: 4.h,
                        ),
                        Container(
                          height: 1.h,
                          margin: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                            Color(0xFFFFC5AC).withOpacity(0.25),
                            Color(0xFFFFC5AC).withOpacity(0.6),
                            Color(0xFFFFC5AC).withOpacity(0.25),
                          ])),
                        ),
                        SizedBox(
                          height: 4.h,
                        ),
                      ],
                    )
                ],
              );
            }).toList(),
          ),
        );
      }
      // Hiển thị empty state chỉ khi không loading và không có dữ liệu
      else {
        return _buildEmptyState();
      }
    });
  }

  // Widget xây dựng hiệu ứng shimmer
  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(3, (_) => const EventCardItemPlaceholder()),
    );
  }

  // Widget xây dựng trạng thái rỗng
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: 32.h, horizontal: 16.w), // Thêm padding
        child: Text(
          'Không có sự kiện nào sắp tới',
          textAlign: TextAlign.center, // Căn giữa text
          style: TextStyle(
            fontSize: 18.sp, // Responsive font size
            color: Colors.grey[600], // Màu xám nhẹ
            fontStyle: FontStyle.italic, // In nghiêng
          ),
        ),
      ),
    );
  }
}
