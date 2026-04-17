import 'dart:convert';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/notifications/firebase_push_service.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final store = JwtLocalDataSource();
    final api = AuthApi(DioClient.ensure());

    final (token, roleRaw) = await store.read();
    final refresh = (await store.readRefreshToken())?.trim() ?? '';

    if (!mounted) return;

    final role = roleRaw.trim().toUpperCase();

    if (role.isEmpty) {
      DioClient.clearToken();
      context.go('/login');
      return;
    }

    String access = token.trim();

    if (access.isEmpty || _isJwtExpired(access)) {
      if (refresh.isEmpty) {
        await store.clear();
        DioClient.clearToken();

        if (!mounted) return;
        context.go('/login');
        return;
      }

      try {
        final res = await api.refresh(refresh);
        final data = res.data;

        if (data is! Map) {
          throw Exception('BAD_REFRESH_RESPONSE');
        }

        final newToken = (data['token'] ?? '').toString().trim();
        final newRefresh = (data['refreshToken'] ?? '').toString().trim();

        if (newToken.isEmpty || newRefresh.isEmpty) {
          throw Exception('MISSING_TOKENS');
        }

        await store.save(
          token: newToken,
          role: role,
          refreshToken: newRefresh,
        );

        DioClient.setToken(newToken);
        access = newToken;
      } catch (e, st) {
        debugPrint('Splash refresh failed: $e');
        debugPrint('$st');

        final shouldClear = _shouldClearAfterRefreshFailure(e);

        if (shouldClear) {
          await store.clear();
          DioClient.clearToken();
        }

        if (!mounted) return;
        context.go('/login');
        return;
      }
    } else {
      DioClient.setToken(access);
    }

    if (!mounted) return;
    context.go(role == 'SUPER_ADMIN' ? '/manager' : '/owner');

    Future.microtask(() async {
      try {
        await FirebasePushService()
            .initForAdmin()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Push init from SplashGate failed or timed out: $e');
      }
    });
  }

  bool _shouldClearAfterRefreshFailure(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;

      if (status == 401 || status == 403) {
        return true;
      }

      return false;
    }

    final msg = e.toString().toUpperCase();

    return msg.contains('NO_REFRESH') ||
        msg.contains('BAD_REFRESH') ||
        msg.contains('BAD_REFRESH_RESPONSE') ||
        msg.contains('MISSING_TOKENS') ||
        msg.contains('REFRESH TOKEN') ||
        msg.contains('INVALID_REFRESH');
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);

      if (map is! Map) return true;

      final exp = map['exp'];
      if (exp == null) return true;

      final expSeconds =
          (exp is num) ? exp.toInt() : int.parse(exp.toString());
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return nowSeconds >= expSeconds;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}