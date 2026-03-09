import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/notifications_admin/data/model/admin_notification_model.dart';

import 'package:dio/dio.dart';

class AdminNotificationsApi {
  final Dio dio;

  AdminNotificationsApi(this.dio);

  Future<List<AdminNotificationModel>> getNotifications() async {
    final response = await dio.get('/notifications/admin');

    final data = response.data;
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((e) => AdminNotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await dio.get('/notifications/admin/unread-count');
    final data = response.data;

    if (data is Map && data['count'] != null) {
      return int.tryParse(data['count'].toString()) ?? 0;
    }
    return 0;
  }

  Future<void> markAsRead(int id) async {
    await dio.put('/notifications/admin/$id/read');
  }

  Future<void> deleteNotification(int id) async {
    await dio.delete('/notifications/admin/$id');
  }
}