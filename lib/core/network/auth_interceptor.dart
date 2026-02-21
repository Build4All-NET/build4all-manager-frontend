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
    final p = (o.uri.path.isNotEmpty ? o.uri.path : o.path).toLowerCase();

    // ✅ allow auth/register endpoints without token
    if (p.contains('/auth/')) return true;
    if (p.contains('/login')) return true;
    if (p.contains('/register')) return true;
    if (p.contains('/otp')) return true;

    return false;
  }

  bool _isMeRequest(RequestOptions o) {
    // Use uri.path when possible (more reliable than o.path)
    var p = (o.uri.path.isNotEmpty ? o.uri.path : o.path).toLowerCase();

    // normalize trailing slash
    if (p.endsWith('/')) p = p.substring(0, p.length - 1);

    // We only want to logout on 404 for the "who am I" endpoints
    final endsWithMe = p.endsWith('/me');

    // extra safety: only for GET
    final isGet = (o.method.toUpperCase() == 'GET');

    return endsWithMe && isGet;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
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

    // ✅ DB reset case:
    // token exists locally, but user is deleted -> backend may return 404 on /me
    final shouldForceLogout =
        (code == 401 || code == 403) || (code == 404 && _isMeRequest(err.requestOptions));

    // don't redirect on public/auth calls (wrong password etc.)
    if (shouldForceLogout && !_isPublicRequest(err.requestOptions)) {
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