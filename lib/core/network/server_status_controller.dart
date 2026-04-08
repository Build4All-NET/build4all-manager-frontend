import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum ServerUiStatus { ok, waiting, down }

class ServerStatusController {
  ServerStatusController._();

  static final ValueNotifier<ServerUiStatus> status =
      ValueNotifier(ServerUiStatus.ok);

  static const Duration popupDelay = Duration(seconds: 3);
  static const Duration retryInterval = Duration(seconds: 3);

  static Timer? _popupTimer;
  static Timer? _retryTimer;
  static String? _baseUrl;

  static void init({required String baseUrl}) {
    _baseUrl = baseUrl.trim();
  }

  /// ✅ Call this when Dio detects server down (timeouts/connection/500+)
  /// First 15 seconds -> waiting (banner only)
  /// After 15 seconds -> down (show popup)
  static void markDownCandidate() {
    // already waiting or already showing popup
    if (status.value == ServerUiStatus.waiting ||
        status.value == ServerUiStatus.down) {
      return;
    }

    status.value = ServerUiStatus.waiting;

    _popupTimer?.cancel();
    _popupTimer = Timer(popupDelay, () {
      // if still not recovered after 15s -> show popup and start retry loop
      if (status.value == ServerUiStatus.waiting) {
        status.value = ServerUiStatus.down;
        _startAutoRetry();
      }
    });
  }

  static void markOk() {
    if (status.value == ServerUiStatus.ok) return;

    status.value = ServerUiStatus.ok;
    _popupTimer?.cancel();
    _popupTimer = null;
    _stopAutoRetry();
  }

  static void _startAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(retryInterval, (_) => checkNow());
  }

  static void _stopAutoRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /// ✅ Probe server. If any response < 500 -> consider server back.
  static Future<void> checkNow() async {
    final baseUrl = _baseUrl;
    if (baseUrl == null || baseUrl.isEmpty) return;

    final probeDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final root = _stripApi(cleanBase);

    final urls = <String>[
      cleanBase,
      '$cleanBase/health',
      '$root/actuator/health',
      '$root/health',
      root, // even 404 means server reachable
    ];

    for (final url in urls) {
      try {
        final res = await probeDio.get(
          url,
          options: Options(
            followRedirects: false,
            validateStatus: (s) => true,
          ),
        );

        final sc = res.statusCode ?? 0;
        if (sc > 0 && sc < 500) {
          markOk();
          return;
        }
      } catch (_) {
        // try next
      }
    }
  }

  static String _stripApi(String baseUrl) {
    var u = baseUrl;
    if (u.endsWith('/api')) u = u.substring(0, u.length - 4);
    return u;
  }
}
