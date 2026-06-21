import 'package:dio/dio.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<NotificationModel>> fetchNotifications({int limit = 20, int offset = 0}) async {
    try {
      final response = await _dio.get(
        'notifications',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final List data = response.data['notifications'];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead([String? notificationId]) async {
    try {
      await _dio.put(
        'notifications',
        data: notificationId != null ? {'notificationId': notificationId} : {},
      );
    } catch (e) {
      rethrow;
    }
  }
}
