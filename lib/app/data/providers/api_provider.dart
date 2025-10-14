import 'package:dio/dio.dart' hide Response;
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../../utils/logger_utils.dart';

class ApiProvider extends GetxService {
  static const String baseUrl = 'https://cloudrun-v2.xemlicham.com';
  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _initializeDio();
  }

  void _initializeDio() {
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

    // Add interceptors for logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          LoggerUtils.debug('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          LoggerUtils.debug('API Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          LoggerUtils.error('API Error: ${error.requestOptions.path}', error);
          return handler.next(error);
        },
      ),
    );
  }

  /// GET request
  Future<dio.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      LoggerUtils.error('GET request failed: $path', e);
      rethrow;
    }
  }

  /// POST request
  Future<dio.Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      LoggerUtils.error('POST request failed: $path', e);
      rethrow;
    }
  }

  /// PUT request
  Future<dio.Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      LoggerUtils.error('PUT request failed: $path', e);
      rethrow;
    }
  }

  /// DELETE request
  Future<dio.Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      LoggerUtils.error('DELETE request failed: $path', e);
      rethrow;
    }
  }
}
