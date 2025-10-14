import 'package:nhac_lich_viet/app/modules/events/views/designed_event_item.dart';
import 'package:nhac_lich_viet/app/routes/app_pages.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart'; // Thêm LoggerUtils
import 'package:nhac_lich_viet/app/widgets/event_card_item_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../controllers/events_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../data/models/event_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nhac_lich_viet/app/modules/detail/services/lunar_service.dart';
import 'dart:io' show Platform;
import 'package:nhac_lich_viet/app/theme/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nhac_lich_viet/app/utils/snackbar_utils.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class EventsView extends StatefulWidget {
  const EventsView({Key? key}) : super(key: key);

  @override
  _EventsViewState createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> with TickerProviderStateMixin {
  final EventsController controller = Get.find();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _rippleController;
  AnimationController? _headerController;
  late PageController _pageController;
  late ScrollController _tabScrollController;
  int _currentPageIndex = 0;
  final GlobalKey _tabRowKey = GlobalKey();
  final Map<int, ScrollController> _pageScrollControllers = {};
  final Map<int, double> _pageScrollOffsets = {};
  Worker? _filterListener;
  bool _isCompactHeader = false;
  final TextEditingController _feedbackController = TextEditingController();
  final GlobalKey _searchShowcaseKey = GlobalKey();
  final GlobalKey _addShowcaseKey = GlobalKey();
  final GlobalKey _swipeShowcaseKey = GlobalKey();
  BuildContext? _showcaseContext;
  bool _isShowcaseActive = false;
  static const String _kShowcaseSeenPref = 'events_showcase_seen';

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageController = PageController();
    _tabScrollController = ScrollController();

    // Listen to filter changes to update page
    // Schedule this after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterListener = ever(controller.selectedFilter, (filter) {
        final newIndex =
            controller.uiFilterTabs.indexWhere((tab) => tab['title'] == filter);
        if (newIndex != -1 &&
            newIndex != _currentPageIndex &&
            _pageController.hasClients) {
          setState(() {
            _currentPageIndex = newIndex;
          });
          _pageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _scrollTabToCenter(newIndex);
          _syncHeaderWithPage(newIndex);
        }
      });
      _syncHeaderWithPage(_currentPageIndex);
      Future.microtask(_maybeStartShowcase);
    });
  }

  @override
  void dispose() {
    _filterListener?.dispose();
    _rippleController.dispose();
    _headerController?.dispose();
    _pageController.dispose();
    _tabScrollController.dispose();
    // Dispose all page scroll controllers
    _pageScrollControllers.forEach((_, controller) {
      controller.dispose();
    });
    _pageScrollControllers.clear();
    _pageScrollOffsets.clear();
    _feedbackController.dispose();
    super.dispose();
  }

  ScrollController _getScrollControllerForPage(int index) {
    if (!_pageScrollControllers.containsKey(index)) {
      final controller = ScrollController();
      controller.addListener(() {
        if (!mounted || !controller.hasClients) return;
        _handleScrollOffset(controller.offset, index);
      });
      _pageScrollControllers[index] = controller;
    }
    return _pageScrollControllers[index]!;
  }

  void _handleScrollOffset(double offset, int pageIndex) {
    if (!mounted) return;
    _pageScrollOffsets[pageIndex] = offset;
    if (pageIndex != _currentPageIndex) return;

    final shouldBeCompact = offset > 50; // Threshold for compact mode

    if (shouldBeCompact != _isCompactHeader) {
      setState(() {
        _isCompactHeader = shouldBeCompact;
      });

      if (_headerController != null) {
        if (_isCompactHeader) {
          _headerController!.forward();
        } else {
          _headerController!.reverse();
        }
      }
    }
  }

  void _syncHeaderWithPage(int pageIndex) {
    final controller = _pageScrollControllers[pageIndex];
    if (controller != null && controller.hasClients) {
      _handleScrollOffset(controller.offset, pageIndex);
    } else {
      final storedOffset = _pageScrollOffsets[pageIndex] ?? 0;
      _handleScrollOffset(storedOffset, pageIndex);
    }
  }

  Future<void> _maybeStartShowcase() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_kShowcaseSeenPref) ?? false;
    if (!hasSeen) {
      await prefs.setBool(_kShowcaseSeenPref, true);
      // Chờ tới khi ShowCaseWidget dựng xong (có context)
      const Duration pollInterval = Duration(milliseconds: 120);
      int attempts = 0;
      while (_showcaseContext == null && mounted && attempts < 15) {
        await Future.delayed(pollInterval);
        attempts++;
      }
      if (!mounted || _showcaseContext == null) return;
      await Future.delayed(const Duration(milliseconds: 200));
      _startShowcaseSequence();
    }
  }

  void _restartShowcaseFromHelp() async {
    if (!mounted) return;

    // Bảo đảm quay lại tab "Tất cả" để các bước hướng dẫn có đủ widget mục tiêu
    if (controller.selectedFilter.value != 'Tất cả') {
      controller.filterEventsByTitle('Tất cả');

      const Duration pollInterval = Duration(milliseconds: 50);
      int attempts = 0;
      while (mounted && _currentPageIndex != 0 && attempts < 12) {
        await Future.delayed(pollInterval);
        attempts++;
      }
    }

    _startShowcaseSequence();
  }

  void _startShowcaseSequence() {
    if (!mounted || _showcaseContext == null) return;
    setState(() {
      _isShowcaseActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showcaseContext == null) return;
      ShowCaseWidget.of(_showcaseContext!)?.startShowCase([
        _searchShowcaseKey,
        _addShowcaseKey,
        _swipeShowcaseKey,
      ]);
    });
  }

  void _handleShowcaseFinished() {
    if (!mounted) return;
    setState(() {
      _isShowcaseActive = false;
    });
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_kShowcaseSeenPref, true));
  }

  void _goToNextShowcaseStep({bool isLast = false}) {
    if (_showcaseContext == null) return;
    final showcaseState = ShowCaseWidget.of(_showcaseContext!);
    if (isLast) {
      if (mounted) {
        setState(() {
          _isShowcaseActive = false;
        });
      }
      showcaseState?.dismiss();
    } else {
      showcaseState?.next();
    }
  }

  Widget _buildShowcaseTooltip({
    required String title,
    required String description,
    required VoidCallback onNext,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: 240.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            description,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                minimumSize: Size(100.w, 40.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Text(isLast ? 'Hoàn tất' : 'Tiếp theo'),
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildAppDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32.r,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      'NL',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Nhắc lịch Việt',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Quản lý ngày quan trọng của bạn',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerTile(
                    icon: Icons.feedback_outlined,
                    title: 'Feedback',
                    subtitle: 'Gửi góp ý cho đội ngũ phát triển',
                    onTap: () {
                      Navigator.of(context).pop();
                      Future.microtask(_showFeedbackDialog);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.share_outlined,
                    title: 'Chia sẻ với bạn bè',
                    subtitle: 'Lan tỏa ứng dụng đến mọi người',
                    onTap: () {
                      Navigator.of(context).pop();
                      Share.share(
                          'Mình đang dùng ứng dụng Nhắc lịch Việt để quản lý các ngày quan trọng. Bạn thử tải về nhé!');
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.star_rate_outlined,
                    title: 'Đánh giá ứng dụng',
                    subtitle: 'Chia sẻ cảm nhận của bạn',
                    onTap: () {
                      Navigator.of(context).pop();
                      Future.microtask(_showRatingPrompt);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20.r,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
      ),
      onTap: onTap,
    );
  }

  void _showFeedbackDialog() {
    _feedbackController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Gửi feedback'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có góp ý hay phản hồi nào? Hãy chia sẻ với chúng tôi!',
                style: TextStyle(fontSize: 15.sp, color: Colors.grey[700]),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung feedback...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _submitFeedback,
            child: const Text('Gửi'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _submitFeedback() async {
    final content = _feedbackController.text.trim();
    if (content.isEmpty) {
      SnackbarUtils.showWarning('Vui lòng nhập nội dung feedback.');
      return;
    }

    final emailUri = Uri(
      scheme: 'mailto',
      path: 'congtinh07082004@gmail.com',
      query: _encodeQueryParameters({
        'subject': 'Feedback ứng dụng Nhắc lịch Việt',
        'body': '$content\n\n---\nĐược gửi từ ứng dụng Nhắc lịch Việt',
      }),
    );

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    try {
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        SnackbarUtils.showSuccess('Đang mở ứng dụng email để gửi feedback.');
      } else {
        SnackbarUtils.showWarning(
            'Không tìm thấy ứng dụng email mặc định. Bạn có thể gửi phản hồi tới congtinh07082004@gmail.com.');
      }
    } catch (e) {
      LoggerUtils.error('Error launching email app', e);
      SnackbarUtils.showWarning(
          'Không mở được ứng dụng email. Vui lòng gửi phản hồi tới congtinh07082004@gmail.com.');
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
  }

  void _showRatingPrompt() {
    double ratingValue = 0;
    Get.dialog(
      Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.9),
                          AppColors.primary,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72.w,
                          height: 72.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(36.r),
                          ),
                          child: Icon(Icons.emoji_emotions, color: AppColors.primary, size: 40.sp),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Đánh giá chất lượng dịch vụ',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Hãy để lại đánh giá để giúp chúng mình hoàn thiện hơn!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isFilled = ratingValue >= starIndex;
                            return IconButton(
                              onPressed: () {
                                setState(() {
                                  ratingValue = starIndex.toDouble();
                                });
                              },
                              padding: EdgeInsets.zero,
                              iconSize: 40.sp,
                              splashRadius: 24.r,
                              color: isFilled
                                  ? AppColors.primary
                                  : Colors.grey.withValues(alpha: 0.3),
                              icon: Icon(
                                isFilled ? Icons.star : Icons.star_border,
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 24.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: ratingValue <= 0
                                ? null
                                : () {
                                    Get.back();
                                    Future.microtask(_openStoreForRating);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: Text(
                              'Đánh giá ngay',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'Để sau',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _openStoreForRating() async {
    const androidPackageName = 'com.example.nhac_lich_viet';
    const iosAppId = '0000000000'; // Thay bằng App Store ID khi có

    Uri? primaryUri;
    Uri? fallbackUri;

    if (Platform.isAndroid) {
      primaryUri = Uri.parse('market://details?id=$androidPackageName');
      fallbackUri = Uri.parse(
          'https://play.google.com/store/apps/details?id=$androidPackageName');
    } else if (Platform.isIOS) {
      primaryUri = Uri.parse('itms-apps://itunes.apple.com/app/id$iosAppId');
      fallbackUri = Uri.parse('https://apps.apple.com/app/id$iosAppId');
    }

    if (primaryUri == null) {
      SnackbarUtils.showWarning(
          'Không hỗ trợ đánh giá trên nền tảng này. Vui lòng tìm kiếm "Nhắc lịch Việt" trên cửa hàng ứng dụng.');
      return;
    }

    Future<bool> tryLaunch(Uri uri) async {
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        LoggerUtils.error('Rate app launch failed for $uri', e);
        return false;
      }
    }

    if (await tryLaunch(primaryUri)) {
      return;
    }

    if (fallbackUri != null && await tryLaunch(fallbackUri)) {
      return;
    }

    SnackbarUtils.showWarning(
        'Không thể mở cửa hàng ứng dụng. Vui lòng tìm kiếm "Nhắc lịch Việt" và đánh giá thủ công.');
  }

  void _scrollTabToCenter(int index) {
    if (!_tabScrollController.hasClients) return;

    // Wait for next frame to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabScrollController.hasClients) return;

      // Calculate approximate position based on index
      // Each tab has padding 4.w on each side + internal padding 16.w on each side
      // Plus the text width which varies
      double estimatedPosition = 0;

      // Estimate position by assuming average tab width
      const double averageTabWidth = 100.0; // Adjust based on your content
      const double tabPadding = 8.0; // 4.w * 2

      estimatedPosition = index * (averageTabWidth + tabPadding);

      // Center the tab in viewport
      final double viewportWidth =
          _tabScrollController.position.viewportDimension;
      final double targetScroll =
          estimatedPosition - (viewportWidth / 2) + (averageTabWidth / 2);

      // Ensure we don't scroll beyond bounds
      final double maxScroll = _tabScrollController.position.maxScrollExtent;
      final double finalScroll = targetScroll.clamp(0.0, maxScroll);

      // Animate to position
      _tabScrollController.animateTo(
        finalScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatTodayHeaderDate(DateTime date) {
    return DateFormat('\'ngày\' d-M-yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: _handleShowcaseFinished,
      builder: Builder(
        builder: (context) {
          _showcaseContext = context;
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            drawer: _buildAppDrawer(),
            body: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/events_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: _buildMainContent(),
            ),
            floatingActionButton: Obx(() {
              return Visibility(
                visible: controller.selectedFilter.value == 'Tất cả',
                child: Showcase.withWidget(
                  key: _addShowcaseKey,
                  targetShapeBorder: const CircleBorder(),
                  disableDefaultTargetGestures: true,
                  width: 260.w,
                  height: 220.h,
                  container: _buildShowcaseTooltip(
                    title: 'Thêm lịch mới',
                    description:
                        'Nhấn để tạo sự kiện và đặt lời nhắc mới cho bạn hoặc người thân.',
                    onNext: () => _goToNextShowcaseStep(),
                  ),
                  child: AbsorbPointer(
                    absorbing: _isShowcaseActive,
                    child: GestureDetector(
                      onTap: controller.goToAddEvent,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            painter: RippleRingPainter(
                              _rippleController,
                              color: const Color(0xFF2AC769)
                                  .withOpacity(0.7),
                              strokeWidth: 2.5.w,
                              expansionFactor: 1.5,
                            ),
                            size: Size(78.w, 78.h),
                          ),
                          Container(
                            height: 70.h,
                            width: 70.w,
                            padding: EdgeInsets.all(5.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2AC769), Color(0xFF1FA259)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 8),
                                  blurRadius: 16,
                                  color: const Color(0xFF1FA259)
                                      .withOpacity(0.35),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF24C16B), Color(0xFF39D27D)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(14.r),
                                  child: Image.asset(
                                    'assets/icons/add_event.png',
                                    width: 26.w,
                                    height: 26.h,
                                    color: Colors.white,
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
            }),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return Obx(() {
      // Chỉ hiển thị shimmer khi loading và hoàn toàn không có dữ liệu cache
      final bool hasAnyData = controller.pastEvents.isNotEmpty ||
          controller.todayEvents.isNotEmpty ||
          controller.upcomingEvents.isNotEmpty;

      if (controller.isLoading.value && !hasAnyData) {
        return _buildShimmerLoading();
      }

      if (controller.isError.value) {
        return _buildErrorWidget();
      }

      final String filterTitle = controller.selectedFilter.value;

      return Column(
        children: [
          _buildHeaderWithSearch(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  _buildFilterButtons(),
                  if (_isShowcaseActive) Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                    child: _buildSwipeShowcaseCard(),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: controller.uiFilterTabs.length,
                      onPageChanged: (index) {
                        if (index >= controller.uiFilterTabs.length) return;
                        setState(() {
                          _currentPageIndex = index;
                        });
                        final filterTitle = controller.uiFilterTabs[index]['title']!;
                        controller.filterEventsBy(filterTitle);
                        _scrollTabToCenter(index);
                        _syncHeaderWithPage(index);
                      },
                      itemBuilder: (context, index) {
                        final filterTitle = controller.uiFilterTabs[index]['title']!;
                        return RefreshIndicator(
                          onRefresh: controller.refreshData,
                          color: AppColors.primary,
                          child: _buildEventListViewForFilter(filterTitle, index),
                        );
                      },
                    ),
                  ),
                  Obx(() => Visibility(
                        visible: controller.selectedFilter.value != 'Tất cả',
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          child: AbsorbPointer(
                            absorbing: _isShowcaseActive,
                            child: GestureDetector(
                              onTap: () {
                                final selectedCategory = controller.eventCategories
                                    .firstWhereOrNull(
                                        (cat) => cat.title == filterTitle);

                                if (selectedCategory != null) {
                                LoggerUtils.debug(
                                    "Navigating to Create Event from EventsView button with category: ${selectedCategory.title}");
                                Get.toNamed(
                                  Routes.CREATE_NEW_EVENT,
                                  arguments: {
                                    'category': selectedCategory,
                                    'selectedDate': DateTime.now(),
                                  },
                                );
                              } else {
                                LoggerUtils.warning(
                                    "Category '$filterTitle' not found when trying to add event from EventsView (non-'Tất cả' filter). Navigating to add event flow.");
                                controller.goToAddEvent();
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                  vertical: 16.h, horizontal: 20.w),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2AC769),
                                    Color(0xFF1FA259),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18.r),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        const Color(0xFF2AC769).withOpacity(0.35),
                                    offset: const Offset(0, 8),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 28.r,
                                    height: 28.r,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Flexible(
                                    child: Text(
                                      'Thêm sự kiện "$filterTitle"',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              ),
                            )),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6ECE7),
      highlightColor: const Color(0xFFF5F8F6),
      period: const Duration(milliseconds: 1200),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: 10,
        itemBuilder: (_, __) => const EventCardItemPlaceholder(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'Có lỗi xảy ra khi tải sự kiện.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 18.sp),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: controller.refreshData,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithSearch() {
    final now = DateTime.now();

    return AnimatedBuilder(
      animation: _headerController ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(

          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, _isCompactHeader ? 16.h : 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First row with 3 buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Drawer button
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          // Nút trợ giúp: khởi động lại hướng dẫn bất cứ lúc nào
                          GestureDetector(
                            onTap: _restartShowcaseFromHelp,
                            child: Container(
                              width: 44.w,
                              height: 44.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.help_outline,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Bước 1: Highlight nút tìm kiếm
                          Showcase.withWidget(
                            key: _searchShowcaseKey,
                            targetShapeBorder: const CircleBorder(),
                            disableDefaultTargetGestures: true,
                            width: 260.w,
                            height: 220.h,
                            container: _buildShowcaseTooltip(
                              title: 'Tìm kiếm sự kiện',
                              description:
                                  'Ấn vào đây để tra cứu nhanh bất kỳ sự kiện nào trong danh sách.',
                              onNext: () => _goToNextShowcaseStep(),
                            ),
                            child: AbsorbPointer(
                              absorbing: _isShowcaseActive,
                              child: GestureDetector(
                                onTap: () => Get.toNamed(Routes.EVENT_SEARCH),
                                child: Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isCompactHeader ? 12.h : 32.h,
                  ),

                  // Date information - animated between compact and full mode
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _isCompactHeader
                        ? Container(
                            key: const ValueKey('compact'),
                            child: Text(
                              '${_getVietnameseDayName(now.weekday)} ${_formatDate(now)}',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Container(
                            key: const ValueKey('full'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day of week (Vietnamese)
                                Text(
                                  _getVietnameseDayName(now.weekday),
                                  style: TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),

                                SizedBox(height: 8.h),

                                // Date
                                Text(
                                  _formatDate(now),
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),

                                SizedBox(height: 4.h),

                                // Lunar date
                                Text(
                                  _getLunarDateString(now),
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
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
        );
      },
    );
  }

  String _getVietnameseDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ 2';
      case 2: return 'Thứ 3';
      case 3: return 'Thứ 4';
      case 4: return 'Thứ 5';
      case 5: return 'Thứ 6';
      case 6: return 'Thứ 7';
      case 7: return 'Chủ nhật';
      default: return '';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _getLunarDateString(DateTime date) {
    try {
      final lunarDate = LunarService.getSolarToLunar(date);
      return '${lunarDate.day.toString().padLeft(2, '0')}-${lunarDate.month} âm lịch';
    } catch (e) {
      return '';
    }
  }

  Widget _buildFilterButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
      child: Obx(() {
        if (controller.isLoading.value && controller.uiFilterTabs.isEmpty) {
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
        if (controller.uiFilterTabs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEF6EF),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          child: SingleChildScrollView(
            key: _tabRowKey,
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.uiFilterTabs.map((tab) {
                final String tabTitle = tab['title']!;
                final bool isSelected =
                    controller.selectedFilter.value == tabTitle;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: GestureDetector(
                    onTap: () {
                      controller.filterEventsBy(tabTitle);
                      final index = controller.uiFilterTabs.indexOf(tab);
                      if (index != -1 && _pageController.hasClients) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        _scrollTabToCenter(index);
                        _syncHeaderWithPage(index);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 22.w : 20.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF24C16B),
                                  const Color(0xFF57D488),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.white.withOpacity(0.92),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF24C16B).withOpacity(0.35)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFD8E6D8),
                        ),
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary.withOpacity(0.82),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Container(
                                width: 8.r,
                                height: 8.r,
                                margin: EdgeInsets.only(right: 6.w),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            Text(tabTitle),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSwipeShowcaseCard() {
    return Showcase.withWidget(
      key: _swipeShowcaseKey,
      disableDefaultTargetGestures: true,
      width: 280.w,
      height: 260.h,
      container: _buildShowcaseTooltip(
        title: 'Vuốt để thao tác nhanh',
        description:
            'Vuốt sang trái để mở 3 nút:\n🖊  Chỉnh sửa lịch này\n📤  Gửi cho bạn bè\n❌  Xóa sự kiện khỏi danh sách',
        onNext: () => _goToNextShowcaseStep(isLast: true),
        isLast: true,
      ),
      child: Slidable(
        key: const ValueKey('showcase_demo_card'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.72,
          children: [
            _buildTutorialAction(
              color: const Color(0xFFE3E9FF),
              icon: Icons.edit,
              iconColor: const Color(0xFF3461FF),
              label: 'Sửa',
              textColor: const Color(0xFF3461FF),
            ),
            _buildTutorialAction(
              color: const Color(0xFFE5F8EF),
              icon: Icons.share,
              iconColor: const Color(0xFF1BAE6C),
              label: 'Chia sẻ',
              textColor: const Color(0xFF1BAE6C),
            ),
            _buildTutorialAction(
              color: const Color(0xFFFFE8E8),
              icon: Icons.delete_outline,
              iconColor: const Color(0xFFE45A5A),
              label: 'Xóa',
              textColor: const Color(0xFFE45A5A),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: const Color(0xFFF4FBF7),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFCDEEDA)),
          ),
          child: Row(
            children: [
              Icon(Icons.swipe_left_alt, color: AppColors.primaryDark, size: 32.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Vuốt nhẹ sang trái thẻ này để thử các nút nhanh.',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialAction({
    required Color color,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      width: 78.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22.sp),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventListViewForFilter(String filterTitle, int pageIndex) {
    // Get filtered events based on the specific filter
    final List<Event> filteredPast = [];
    final List<Event> filteredToday = [];
    final List<Event> filteredUpcoming = [];

    // Filter events based on the provided filterTitle
    _filterEventsForTab(
        filterTitle, filteredPast, filteredToday, filteredUpcoming);

    if (filteredToday.isEmpty &&
        filteredUpcoming.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không có sự kiện nào trong danh mục "$filterTitle"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      controller: _getScrollControllerForPage(pageIndex),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 4.h,
        bottom: 80.h,
      ),
      children: [
        if (filteredToday.isNotEmpty) ...[
          SizedBox(height: 8.h),
          _buildListHeader(filteredToday.first.eventDate),
          SizedBox(height: 4.h),
          ...filteredToday.map((event) => DesignedEventItem(
                type: 0,
                event: event,
                remainingDaysText: 'Hôm nay',
                statusColor: AppColors.primaryDark,
              )),
          SizedBox(height: 8.h),
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppColors.divider,
          ),
        ],
        if (filteredUpcoming.isNotEmpty) ...[
          SizedBox(height: 8.h),
          ...filteredUpcoming.map((event) => DesignedEventItem(
                type: 1,
                event: event,
                remainingDaysText:
                    controller.getDaysRemainingText(event.eventDate),
                statusColor: AppColors.primaryDark,
              )),
        ],
      ],
    );
  }

  void _filterEventsForTab(String filterTitle, List<Event> filteredPast,
      List<Event> filteredToday, List<Event> filteredUpcoming) {
    // Get the category ID if not "Tất cả"
    String? categoryId;
    if (filterTitle != 'Tất cả') {
      final category = controller.eventCategories
          .firstWhereOrNull((cat) => cat.title == filterTitle);
      categoryId = category?.id;
    }

    // Use allEvents for consistent display across tabs
    // This prevents content jumping when swiping
    // Note: filteredPast is no longer used as past events are not displayed

    for (final event in controller.allTodayEvents) {
      if (filterTitle == 'Tất cả' || event.categoryId == categoryId) {
        filteredToday.add(event);
      }
    }

    for (final event in controller.allUpcomingEvents) {
      if (filterTitle == 'Tất cả' || event.categoryId == categoryId) {
        filteredUpcoming.add(event);
      }
    }
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
      ..color = color.withValues(alpha: math.max(0, opacity))
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
