// START REPLACE app/services/event_category_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:nhac_lich_viet/app/data/models/event_category_model.dart';
import 'package:nhac_lich_viet/app/utils/logger_utils.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventCategoryService extends GetxService {
  static const String baseUrl = 'https://cloudrun-v2.xemlicham.com';
  late final Dio _dio;
  final _cacheKey =
      'event_categories_v2'; // Cân nhắc đổi key nếu cấu trúc cache thay đổi
  final _cacheDuration = const Duration(hours: 24);

  // *** THÊM BIẾN SharedPreferences ***
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  Completer<EventCategoryService>? _initCompleter;

  static EventCategoryService get to => Get.find<EventCategoryService>();

  @override
  Future<void> onInit() async {
    // Sử dụng onInit của GetxService
    super.onInit();
    await init(); // Gọi hàm init bất đồng bộ
  }

  Future<EventCategoryService> init() async {
    if (_isInitialized) return this; // Tránh init nhiều lần

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<EventCategoryService>();
    try {
      // Initialize Dio
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      LoggerUtils.debug(
          'EventCategoryService initialized with SharedPreferences and Dio.');
      _initCompleter?.complete(this);
      return this;
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Failed to initialize EventCategoryService',
          e,
          stackTrace);
      _initCompleter?.completeError(e, stackTrace);
      rethrow; // Ném lại lỗi để báo hiệu init thất bại
    } finally {
      // Cho phép các lần gọi sau tạo completer mới nếu cần.
      _initCompleter = null;
    }
  }
  // *** KẾT THÚC THÊM INIT ***

  Future<List<EventCategory>> getCachedCategories() async {
    await init();
    try {
      // *** SỬA: Dùng _prefs đã khởi tạo ***
      final String? cachedData = _prefs.getString(_cacheKey);

      if (cachedData != null) {
        final Map<String, dynamic> json = jsonDecode(cachedData);
        final DateTime cacheTime = DateTime.parse(json['timestamp']);
        final Duration difference = DateTime.now().difference(cacheTime);

        if (difference < _cacheDuration) {
          final List<dynamic> data = json['data'] ?? [];
          LoggerUtils.debug(
              'Loaded ${data.length} categories from cache.'); // Thêm log
          return data.map((item) => EventCategory.fromJson(item)).toList();
        } else {
          LoggerUtils.debug('Cache expired for event categories.'); // Thêm log
        }
      }
      LoggerUtils.debug(
          'No valid cache found for event categories.'); // Thêm log
      return [];
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Failed to get cached categories', e, stackTrace); // Log chi tiết hơn
      return [];
    }
  }

  Future<void> cacheCategories(List<EventCategory> categories) async {
    await init();
    try {
      // *** SỬA: Dùng _prefs đã khởi tạo ***
      final Map<String, dynamic> data = {
        'timestamp': DateTime.now().toIso8601String(),
        'data': categories.map((c) => c.toJson()).toList(),
      };

      await _prefs.setString(_cacheKey, jsonEncode(data));
      LoggerUtils.debug(
          'Cached ${categories.length} event categories.'); // Thêm log
    } catch (e, stackTrace) {
      LoggerUtils.error(
          'Failed to cache categories', e, stackTrace); // Log chi tiết hơn
    }
  }

  Future<List<EventCategory>> fetchCategories() async {
    await init();
    try {
      final response = await _dio.get('/event-categories');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dataField = response.data['responseObject'];

        if (dataField == null || dataField is! List) {
          LoggerUtils.warning(
              'API fetched categories but data is invalid.');
          return [];
        }

        final List<dynamic> data = dataField;
        LoggerUtils.debug(
            'Fetched ${data.length} categories from API.');
        return data.map((item) => EventCategory.fromJson(item)).toList();
      }
      LoggerUtils.warning(
          'API fetch categories failed with status: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      LoggerUtils.error('DioException fetching categories from API: ${e.message}', e);
      return [];
    } catch (e, stackTrace) {
      LoggerUtils.error('Error fetching categories from API', e, stackTrace);
      return [];
    }
  }

}
// END REPLACE app/services/event_category_service.dart
