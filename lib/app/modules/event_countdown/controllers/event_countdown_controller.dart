import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/event_model.dart';
import '../../detail/services/lunar_service.dart';
import '../../../services/event_services.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/logger_utils.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../services/event_services.dart';

class EventCountdownController extends GetxController {
  late Event event;
  late Timer _timer;

  static const MethodChannel _imageSaverChannel = MethodChannel('nhac_lich_viet/image_saver');

  final remainingDays = 0.obs;
  final remainingHours = 0.obs;
  final remainingMinutes = 0.obs;
  final remainingSeconds = 0.obs;
  final isEventOngoing = false.obs;
  final canEdit = false.obs;
  final GlobalKey captureKey = GlobalKey();
  final RxBool showShareLayer = false.obs;
  Uint8List? lastCapturedImage;
  final eventTitle = ''.obs;
  final eventDate = DateTime.now().obs;
  final lunarDate = ''.obs;
  final solarDate = ''.obs;
  final dayName = ''.obs;
  late final String backgroundImage;

  static const List<String> _backgroundImages = [
    'assets/images/events_background_countdown.jpg',
    'assets/images/events_background_countdown1.jpg',
    'assets/images/events_background_countdown2.jpg',
    'assets/images/events_background_countdown3.jpg',
    'assets/images/events_background_countdown4.jpg',
    'assets/images/events_background_countdown5.jpg',
    'assets/images/events_background_countdown6.jpg',
    'assets/images/events_background_countdown7.jpg',
    'assets/images/events_background_countdown8.jpg',
    'assets/images/events_background_countdown9.jpg',
    'assets/images/events_background_countdown10.jpg',
    'assets/images/events_background_countdown11.jpg',
    'assets/images/events_background_countdown12.jpg',
    'assets/images/events_background_countdown13.jpg',
    'assets/images/events_background_countdown14.jpg',
    'assets/images/events_background_countdown15.jpg',
    'assets/images/events_background_countdown16.jpg',
    'assets/images/events_background_countdown17.jpg',
    'assets/images/events_background_countdown19.jpg',
    'assets/images/events_background_countdown20.jpg',
    'assets/images/events_background_countdown21.jpg',
    'assets/images/events_background_countdown22.jpg',
    'assets/images/events_background_countdown23.jpg',
    'assets/images/events_background_countdown24.jpg',
    'assets/images/events_background_countdown25.jpg',
    'assets/images/events_background_countdown27.jpg',
  ];

  @override
  void onInit() {
    super.onInit();
    // Get event from arguments
    event = Get.arguments['event'] as Event;

    backgroundImage = _pickBackgroundFor(event);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 50));
      await captureCountdownImage();
    });

    // Initialize values
    eventTitle.value = event.title;
    eventDate.value = event.eventDate;
    canEdit.value = event.eventType.trim().toLowerCase() ==
        EventTypeEnum.user_event.value;

    // Format dates
    _updateDateInfo();

    // Start countdown timer
    _startCountdownTimer();
  }

  @override
  void onClose() {
    _timer.cancel();
    super.onClose();
  }

  void _updateDateInfo() {
    final eventDateTime = event.eventDate;

    // Solar date formatting (Vietnamese style)
    solarDate.value = _getVietnameseDateString(eventDateTime);

    // Day name (Vietnamese)
    dayName.value = _getVietnameseDayName(eventDateTime.weekday);

    // Lunar date
    try {
      final lunar = LunarService.getSolarToLunar(eventDateTime);
      lunarDate.value = '${lunar.day}-${lunar.month} âm lịch';
    } catch (e) {
      lunarDate.value = '';
    }

    // Calculate remaining time
    _calculateRemainingTime();
  }

  String _getVietnameseDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Thứ Hai';
      case 2: return 'Thứ Ba';
      case 3: return 'Thứ Tư';
      case 4: return 'Thứ Năm';
      case 5: return 'Thứ Sáu';
      case 6: return 'Thứ Bảy';
      case 7: return 'Chủ Nhật';
      default: return '';
    }
  }

  String _getVietnameseMonthName(int month) {
    switch (month) {
      case 1: return 'Tháng Một';
      case 2: return 'Tháng Hai';
      case 3: return 'Tháng Ba';
      case 4: return 'Tháng Tư';
      case 5: return 'Tháng Năm';
      case 6: return 'Tháng Sáu';
      case 7: return 'Tháng Bảy';
      case 8: return 'Tháng Tám';
      case 9: return 'Tháng Chín';
      case 10: return 'Tháng Mười';
      case 11: return 'Tháng Mười Một';
      case 12: return 'Tháng Mười Hai';
      default: return '';
    }
  }

  String _getVietnameseDateString(DateTime date) {
    return '${_getVietnameseMonthName(date.month)} ${date.day}, ${date.year}';
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final eventDateTime = event.eventDate;

    final difference = eventDateTime.difference(now);

    if (difference.isNegative) {
      // Event has passed
      remainingDays.value = 0;
      remainingHours.value = 0;
      remainingMinutes.value = 0;
      remainingSeconds.value = 0;
      // Treat events that already started as ongoing (still same day)
      if (EventServices.isSameDay(eventDateTime, now)) {
        isEventOngoing.value = true;
      } else {
        isEventOngoing.value = false;
      }
    } else {
      // Calculate days, hours, minutes, seconds
      remainingDays.value = difference.inDays;
      remainingHours.value = difference.inHours % 24;
      remainingMinutes.value = difference.inMinutes % 60;
      remainingSeconds.value = difference.inSeconds % 60;
      // If the event is today and countdown reached zero, mark as ongoing
      isEventOngoing.value =
          difference.inSeconds == 0 && EventServices.isSameDay(eventDateTime, now);
    }
  }

  void _startCountdownTimer() {
    // Update every second to keep the countdown accurate
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  String buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('🎉 ${event.title}');
    buffer.writeln('');
    buffer.writeln('📅 Ngày: ${DateFormat('dd/MM/yyyy').format(event.eventDate)}');
    if (lunarDate.value.isNotEmpty) {
      buffer.writeln('🌙 Âm lịch: ${lunarDate.value}');
    }
    buffer.writeln('');
    buffer.writeln('⏳ Đếm ngược: ${daysText}');
    buffer.writeln('');
    buffer.writeln('Được chia sẻ từ ứng dụng Nhắc lịch Việt');
    return buffer.toString();
  }

  Future<void> shareEvent({Uint8List? imageBytes}) async {
    final bytes = imageBytes ?? await captureCountdownImage();
    if (bytes == null) {
      SnackbarUtils.showError('Không thể chụp màn hình đếm ngược để chia sẻ.');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/countdown_${event.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: buildShareText(),
        );
      } finally {
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      LoggerUtils.error('Error sharing countdown image', e);
      SnackbarUtils.showError('Không thể chia sẻ hình ảnh. Vui lòng thử lại.');
    }
  }

  Future<void> editEvent() async {
    final result = await Get.toNamed(
      Routes.CREATE_NEW_EVENT,
      arguments: {
        'event': event.copyWith(),
        'isEdit': true,
      },
    );
    if (result == true) {
      // Reload event from storage to keep countdown accurate
      final updated =
          Get.find<EventServices>().getEventById(event.id) ?? event;
      event = updated;
      eventTitle.value = event.title;
      eventDate.value = event.eventDate;
      canEdit.value = event.eventType.trim().toLowerCase() ==
          EventTypeEnum.user_event.value;
      _updateDateInfo();
    }
  }

  Future<Uint8List?> captureCountdownImage() async {
    showShareLayer.value = true;
    try {
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary? boundary =
          captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      for (int retry = 0; retry < 10; retry++) {
        if (boundary != null && !boundary.debugNeedsPaint) {
          break;
        }
        await WidgetsBinding.instance.endOfFrame;
        boundary =
            captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      }

      if (boundary == null || boundary.debugNeedsPaint) {
        LoggerUtils.warning(
            'captureCountdownImage boundary not ready (debugNeedsPaint=${boundary?.debugNeedsPaint}).');
        return null;
      }
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      lastCapturedImage = bytes;
      return bytes;
    } catch (e, stackTrace) {
      LoggerUtils.error('Error capturing countdown image', e, stackTrace);
      return null;
    } finally {
      showShareLayer.value = false;
    }
  }

  Future<void> downloadCountdownImage({Uint8List? imageBytes}) async {
    final bytes = imageBytes ?? lastCapturedImage ?? await captureCountdownImage();
    if (bytes == null) {
      SnackbarUtils.showError('Không thể chụp màn hình đếm ngược để tải về.');
      return;
    }

    try {
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        PermissionStatus status;

        if (deviceInfo.version.sdkInt >= 33) { // Android 13+
          status = await Permission.photos.request();
        } else { // Android < 13
          status = await Permission.storage.request();
        }

        if (!status.isGranted) {
          SnackbarUtils.showError('Quyền truy cập bộ nhớ bị từ chối.');
          return;
        }
      }

      final name =
          'nhac_lich_viet_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      final bool? success = await _imageSaverChannel.invokeMethod<bool>(
        'saveImage',
        {
          'bytes': bytes,
          'name': '$name.png',
        },
      );
      if (success == true) {
        SnackbarUtils.showSuccess('Đã lưu hình ảnh vào thư viện.');
      } else {
        SnackbarUtils.showError('Không thể lưu hình ảnh. Vui lòng thử lại.');
      }
    } catch (e, stackTrace) {
      LoggerUtils.error('Error saving countdown image', e, stackTrace);
      SnackbarUtils.showError('Không thể lưu hình ảnh. Vui lòng thử lại.');
    }
  }

  String _pickBackgroundFor(Event event) {
    final normalizedTitle = event.title.trim().toLowerCase();
    if (normalizedTitle == 'ngày phụ nữ việt nam' || normalizedTitle == 'ngày quốc tế phụ nữ') {
      return 'assets/images/events_background_countdown_20-10.jpg';
    }
    if (normalizedTitle == 'ngày halloween') {
      return 'assets/images/events_background_countdown_31-10.jpg';
    }

    if (normalizedTitle == 'ngày nhà giáo việt nam') {
      return 'assets/images/events_background_countdown_20-11.png';
    }

    if (normalizedTitle == 'ngày lễ giáng sinh') {
      return 'assets/images/events_background_countdown_25-12.jpg';
    }
    if (normalizedTitle == 'tết dương lịch' || normalizedTitle == 'tết nguyên đán (tết âm lịch)' || normalizedTitle == 'mùng hai tết' || normalizedTitle == 'mùng ba tết') {
      return 'assets/images/events_background_countdown_tet.jpg';
    }
    if (normalizedTitle == 'tết trung thu, rằm tháng 8 âm lịch') {
      return 'assets/images/events_background_countdown_15-8.jpg';
    }

    return _backgroundImages[Random().nextInt(_backgroundImages.length)];
  }

  String get daysText {
    if (remainingDays.value == 0) {
      return 'Hôm nay';
    } else if (remainingDays.value > 0) {
      return '${remainingDays.value} ngày nữa';
    } else {
      return '${remainingDays.value.abs()} ngày trước';
    }
  }


}
