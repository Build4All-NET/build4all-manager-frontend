import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

class AuthInterceptor extends Interceptor {
  final JwtLocalDataSource jwt;
  final GlobalKey<NavigatorState> navKey;

  bool _redirecting = false;

  AuthInterceptor({
    required this.jwt,
    required this.navKey,
  });

  bool _isPublicRequest(RequestOptions o) {
    final p = o.path.toLowerCase();

    // ✅ allow auth/register endpoints without token
    if (p.contains('/auth/')) return true;
    if (p.contains('/login')) return true;
    if (p.contains('/register')) return true;
    if (p.contains('/otp')) return true;

    return false;
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (!_isPublicRequest(options)) {
        final (token, _) = await jwt.read();
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer ${token.trim()}';
        } else {
          options.headers.remove('Authorization');
        }
      }
    } catch (_) {
      // ignore
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final code = err.response?.statusCode;

    if (code == 401) {
      try {
        await jwt.clear();
      } catch (_) {}

      if (!_redirecting) {
        _redirecting = true;

        final ctx = navKey.currentContext;
        if (ctx != null) {
          ctx.go('/login');
        }

        Future.delayed(const Duration(milliseconds: 600), () {
          _redirecting = false;
        });
      }
    }

    handler.next(err);
  }
}
