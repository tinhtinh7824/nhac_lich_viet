import 'package:nhac_lich_viet/app/modules/profile_event/controllers/profile_event_controller.dart';
import 'package:nhac_lich_viet/app/modules/events/views/designed_event_item.dart';
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:nhac_lich_viet/app/data/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class ProfileEventView extends StatefulWidget {
  const ProfileEventView({super.key});

  @override
  _ProfileEventViewState createState() => _ProfileEventViewState();
}

class _ProfileEventViewState extends State<ProfileEventView>
    with TickerProviderStateMixin {
  final ProfileEventController controller = Get.find();
  late AnimationController _rippleController;
  late PageController _pageController;
  late ScrollController _tabScrollController;
  int _currentPageIndex = 0;
  final Map<int, ScrollController> _pageScrollControllers = {};
  Worker? _categoryListener;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _pageController = PageController();
    _tabScrollController = ScrollController();

    // Listen to category selection changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _categoryListener = ever(controller.selectedCategoryTitle, (title) {
        final tabs = _buildTabsList();
        final newIndex = tabs.indexOf(title);
        if (newIndex != -1 &&
            newIndex != _currentPageIndex &&
            _pageController.hasClients) {
          _currentPageIndex = newIndex;
          _pageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _scrollTabToCenter(newIndex);
        }
      });
    });
  }

  @override
  void dispose() {
    _categoryListener?.dispose();
    _rippleController.dispose();
    _pageController.dispose();
    _tabScrollController.dispose();
    // Dispose all page scroll controllers
    _pageScrollControllers.forEach((_, controller) {
      controller.dispose();
    });
    _pageScrollControllers.clear();
    super.dispose();
  }

  ScrollController _getScrollControllerForPage(int index) {
    if (!_pageScrollControllers.containsKey(index)) {
      _pageScrollControllers[index] = ScrollController();
    }
    return _pageScrollControllers[index]!;
  }

  String _formatTodayHeaderDate(DateTime date) {
    return DateFormat('\'ngày\' d-M-yyyy').format(date);
  }

  List<String> _buildTabsList() {
    // No sorting needed - use categories in their original order
    return ['Tất cả', ...controller.eventCategories.map((cat) => cat.title)];
  }

  void _scrollTabToCenter(int index) {
    if (!_tabScrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabScrollController.hasClients) return;

      const double averageTabWidth = 100.0;
      const double tabPadding = 8.0;

      final double estimatedPosition = index * (averageTabWidth + tabPadding);
      final double viewportWidth =
          _tabScrollController.position.viewportDimension;
      final double targetScroll =
          estimatedPosition - (viewportWidth / 2) + (averageTabWidth / 2);
      final double maxScroll = _tabScrollController.position.maxScrollExtent;
      final double finalScroll = targetScroll.clamp(0.0, maxScroll);

      _tabScrollController.animateTo(
        finalScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SỰ KIỆN CÁ NHÂN',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: Obx(() {
        return Visibility(
          visible: controller.selectedCategoryTitle.value == 'Tất cả',
          child: GestureDetector(
            onTap: () {
              LoggerUtils.debug(
                  "Navigating to Add Event from 'Tất cả' tab FAB in ProfileEventView");
              Get.toNamed(
                Routes.ADD_EVENT,
                arguments: {
                  'selectedDate': DateTime.now(),
                },
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: RippleRingPainter(
                    _rippleController,
                    color: const Color(0xFF6ADF8A),
                    strokeWidth: 2.5.w,
                    expansionFactor: 1.5,
                  ),
                  size: Size(75.w, 75.h), // Tăng size vùng ripple
                ),
                Container(
                  height: 66.h, // Tăng size vòng ngoài
                  width: 66.w, // Tăng size vòng ngoài
                  padding: EdgeInsets.all(5.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6ADF8A),
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 0),
                        blurRadius: 6,
                        spreadRadius: 0,
                        color: AppColors.textPrimary.withOpacity(0.2),
                      ),
                    ],
                  ),
                  child: Container(
                    height: 48.h,
                    width: 48.w,
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryDark,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 0),
                          blurRadius: 3,
                          spreadRadius: 0,
                          color: AppColors.textPrimary.withOpacity(0.25),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icons/add_event.png',
                      width: 24.w,
                      height: 24.h,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Obx(() {
        if (controller.isLoading.value && controller.filteredEvents.isEmpty) {
          return _buildShimmerLoading();
        }

        final String filterTitle = controller.selectedCategoryTitle.value;

        return Column(
          children: [
            _buildFilterButtons(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _buildTabsList().length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                  final tabs = _buildTabsList();
                  if (index < tabs.length) {
                    controller.selectCategory(tabs[index], index);
                    _scrollTabToCenter(index);
                  }
                },
                itemBuilder: (context, index) {
                  final tabs = _buildTabsList();
                  final filterTitle =
                      index < tabs.length ? tabs[index] : 'Tất cả';
                  return RefreshIndicator(
                    onRefresh: () async {
                      await controller.refreshEvents();
                    },
                    color: AppColors.primary,
                    child: _buildEventListViewForFilter(filterTitle),
                  );
                },
              ),
            ),
            SafeArea(
              child: Obx(() => Visibility(
                    visible: controller.selectedCategoryTitle.value != 'Tất cả',
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: () {
                            final selectedCategory = controller.eventCategories
                                .firstWhereOrNull(
                                    (cat) => cat.title == filterTitle);

                            if (selectedCategory != null) {
                              LoggerUtils.debug(
                                  "Navigating to Create Event from ProfileEventView button with category: ${selectedCategory.title}");
                              Get.toNamed(
                                Routes.CREATE_NEW_EVENT,
                                arguments: {
                                  'category': selectedCategory,
                                  'selectedDate': DateTime.now(),
                                },
                              );
                            } else {
                              LoggerUtils.warning(
                                  "Category '$filterTitle' not found in ProfileEventView. Navigating to general add event flow.");
                              Get.toNamed(
                                Routes.ADD_EVENT,
                                arguments: {
                                  'selectedDate': DateTime.now(),
                                },
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            '+ Thêm sự kiện "$filterTitle"',
                            style: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  )),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1200),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: 10,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          height: 80.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      constraints: BoxConstraints(minHeight: 36.h + (2 * 8.h)),
      child: Obx(() {
        if (controller.isLoading.value && controller.eventCategories.isEmpty) {
          return Center(
            child: SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryDark,
              ),
            ),
          );
        }

        // No sorting needed - use categories in their original order
        final tabs = ['Tất cả', ...controller.eventCategories.map((cat) => cat.title)];

        if (tabs.isEmpty) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          controller: _tabScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: tabs.map((tabTitle) {
              final bool isSelected =
                  controller.selectedCategoryTitle.value == tabTitle;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GestureDetector(
                  onTap: () {
                    final index = tabs.indexOf(tabTitle);
                    controller.selectCategory(tabTitle, index);
                    if (_pageController.hasClients) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _scrollTabToCenter(index);
                    }
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryDark
                          : const Color(0xFFD6D6D6),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    constraints: BoxConstraints(minHeight: 36.h),
                    alignment: Alignment.center,
                    child: Text(
                      tabTitle,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Widget _buildEventListViewForFilter(String filterTitle) {
    // Get filtered events based on the specific filter
    final List<Event> filteredEvents = [];

    if (filterTitle == 'Tất cả') {
      filteredEvents.addAll(controller.allUserEvents);
    } else {
      final category = controller.eventCategories
          .firstWhereOrNull((cat) => cat.title == filterTitle);
      if (category != null) {
        filteredEvents.addAll(controller.allUserEvents
            .where((event) => event.categoryId == category.id));
      }
    }

    if (filteredEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filterTitle == 'Tất cả'
                    ? 'Bạn chưa có sự kiện nào.\nHãy thêm sự kiện mới nhé!'
                    : 'Không có sự kiện nào trong danh mục "$filterTitle"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Group events by past, today, upcoming
    final past = <Event>[];
    final today = <Event>[];
    final upcoming = <Event>[];

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    for (final event in filteredEvents) {
      final eventDate = DateTime(
          event.eventDate.year, event.eventDate.month, event.eventDate.day);

      if (eventDate.isBefore(todayDate)) {
        past.add(event);
      } else if (eventDate.isAtSameMomentAs(todayDate)) {
        today.add(event);
      } else {
        upcoming.add(event);
      }
    }

    return ListView(
      controller: _getScrollControllerForPage(_currentPageIndex),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: 80.h,
      ),
      children: [
        if (past.isNotEmpty) ...[
          ...past.map((event) => DesignedEventItem(
                type: -1,
                event: event,
                remainingDaysText: _getRemainingDaysText(event.eventDate),
                statusColor: Colors.grey,
              )),
        ],
        if (today.isNotEmpty) ...[
          SizedBox(height: 24.h),
          _buildListHeader(today.first.eventDate),
          SizedBox(height: 8.h),
          ...today.map((event) => DesignedEventItem(
                type: 0,
                event: event,
                remainingDaysText: 'Hôm nay',
                statusColor: AppColors.primaryDark,
              )),
          SizedBox(height: 16.h),
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppColors.divider,
          ),
        ],
        if (upcoming.isNotEmpty) ...[
          SizedBox(height: 16.h),
          ...upcoming.map((event) => DesignedEventItem(
                type: 1,
                event: event,
                remainingDaysText: _getRemainingDaysText(event.eventDate),
                statusColor: AppColors.primaryDark,
              )),
        ],
      ],
    );
  }

  Widget _buildListHeader(DateTime todayDate) {
    final formattedDate = _formatTodayHeaderDate(todayDate);
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h, left: 4.w, right: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            "Hôm nay: ",
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _getRemainingDaysText(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final difference = eventDay.difference(today).inDays;

    if (difference < 0) {
      final daysAgo = difference.abs();
      if (daysAgo == 1) return 'Hôm qua';
      if (daysAgo == 2) return '2 ngày trước';
      return '$daysAgo ngày trước';
    } else if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Ngày mai';
    } else if (difference == 2) {
      return '2 ngày nữa';
    } else {
      return '$difference ngày nữa';
    }
  }
}

class RippleRingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double strokeWidth;
  final double expansionFactor;

  RippleRingPainter(
    this.animation, {
    required this.color,
    this.strokeWidth = 2.0,
    this.expansionFactor = 1.5,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double value = animation.value;
    final double radius = size.width / 2 * value * expansionFactor;
    final double opacity = 1.0 - value;

    final Paint paint = Paint()
      ..color = color.withOpacity(math.max(0, opacity))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, paint);
  }

  @override
  bool shouldRepaint(covariant RippleRingPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.expansionFactor != expansionFactor;
  }
}
