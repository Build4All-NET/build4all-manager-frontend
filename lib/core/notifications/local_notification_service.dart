import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService _instance = LocalNotificationService._();
  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'manager_high_importance',
      'Manager Notifications',
      description: 'Notifications for manager app',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'manager_high_importance',
      'Manager Notifications',
      channelDescription: 'Notifications for manager app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );

    debugPrint('LocalNotificationService: displayed local notification');
  }
}