import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebasePushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initForAdmin() async {
    // Request notification permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Get current FCM token
    final token = await _messaging.getToken();
    debugPrint('FCM TOKEN => $token');

    if (token != null && token.isNotEmpty) {
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM TOKEN REFRESH => $newToken');
      await _sendTokenToBackend(newToken);
    });
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      await DioClient.ensure().put(
        '/notifications/admin/fcm-token',
        data: {
          'fcmToken': fcmToken,
        },
      );
    } catch (e) {
      debugPrint('Failed to send admin FCM token: $e');
    }
  }
}