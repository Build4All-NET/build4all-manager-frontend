import 'dart:io';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebasePushService {
  FirebasePushService._();
  static final FirebasePushService _instance = FirebasePushService._();
  factory FirebasePushService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initForAdmin() async {
    if (_initialized) {
      debugPrint('FirebasePushService: already initialized');
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        'FirebasePushService: permission status => ${settings.authorizationStatus}',
      );

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      if (!kIsWeb && Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        debugPrint('FirebasePushService: iOS APNS token => $apnsToken');
      }

      final token = await _messaging.getToken();
      debugPrint('FirebasePushService: current FCM token => $token');

      if (token != null && token.trim().isNotEmpty) {
        await _sendTokenToBackend(token.trim());
      } else {
        debugPrint('FirebasePushService: token is null/empty');
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FirebasePushService: token refreshed => $newToken');

        if (newToken.trim().isNotEmpty) {
          await _sendTokenToBackend(newToken.trim());
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'FirebasePushService: foreground message received => '
          'title=${message.notification?.title}, '
          'body=${message.notification?.body}, '
          'data=${message.data}',
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          'FirebasePushService: notification opened app => '
          'title=${message.notification?.title}, '
          'body=${message.notification?.body}, '
          'data=${message.data}',
        );
      });

      _initialized = true;
      debugPrint('FirebasePushService: initialization completed');
    } catch (e) {
      debugPrint('FirebasePushService: init failed => $e');
    }
  }

  Future<void> _sendTokenToBackend(String fcmToken) async {
    try {
      final platform = kIsWeb
          ? 'WEB'
          : Platform.isIOS
              ? 'IOS'
              : 'ANDROID';

      debugPrint(
        'FirebasePushService: sending admin token to backend... '
        'platform=$platform token=$fcmToken',
      );

      final response = await DioClient.ensure().put(
        '/notifications/admin/fcm-token',
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
        },
      );

      debugPrint(
        'FirebasePushService: admin token sync success => '
        '${response.statusCode} ${response.data}',
      );
    } catch (e) {
      debugPrint('FirebasePushService: failed to send admin FCM token => $e');
    }
  }
}