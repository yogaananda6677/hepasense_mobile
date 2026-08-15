import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);
  final ApiClient _api;

  Future<NotificationPage> list({required int page}) async {
    try {
      final response = await _api.dio.get(
        '/api/v1/notifications/',
        queryParameters: {'page': page},
      );
      return NotificationPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _api.dio.get(
        '/api/v1/notifications/unread-count/',
      );
      return (response.data as Map<String, dynamic>)['unread_count'] as int;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<AppNotification> markRead(int id) async {
    try {
      final response = await _api.dio.post('/api/v1/notifications/$id/read/');
      return AppNotification.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.dio.post('/api/v1/notifications/read-all/');
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}
