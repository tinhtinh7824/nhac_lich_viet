import 'package:dio/dio.dart';
import '../data/models/event_model.dart';

class EventApiService {
  static const String baseUrl = 'https://cloudrun-v2.xemlicham.com';
  late final Dio _dio;

  EventApiService() {
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
  }

  /// Fetch all events from API
  Future<List<Event>> fetchAllEvents({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/events',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final eventsData = response.data['responseObject']['events'] as List?;
        if (eventsData == null) {
          return [];
        }

        return eventsData.map((e) => Event.fromJson(e)).toList();
      }

      return [];
    } on DioException catch (e) {
      print('Error fetching events from API: ${e.message}');
      return [];
    } catch (e) {
      print('Unexpected error: $e');
      return [];
    }
  }
}
