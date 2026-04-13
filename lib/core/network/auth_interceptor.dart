import 'dart:async';
import 'package:dio/dio.dart';

import '../../features/auth/data/datasources/jwt_local_datasource.dart';
import '../../features/auth/data/services/auth_api.dart';
import '../network/dio_client.dart';

class AuthInterceptor extends Interceptor {
  final JwtLocalDataSource jwtStore;
  final AuthApi api;

  bool _refreshing = false;
  final List<Completer<void>> _waiters = [];

  AuthInterceptor({
    required this.jwtStore,
    required this.api,
  });

  bool _isAuthPath(RequestOptions o) {
    final p = o.path;
    return p.contains('/auth/refresh') ||
        p.contains('/auth/logout') ||
        p.contains('/auth/login') ||
        p.contains('/auth/admin/login') ||
        p.contains('/auth/manager/login') ||
        p.contains('/auth/superadmin/login');
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      final c = Completer<void>();
      _waiters.add(c);
      return c.future;
    }

    _refreshing = true;

    try {
      final refresh = (await jwtStore.readRefreshToken())?.trim() ?? '';
      if (refresh.isEmpty) {
        throw Exception('NO_REFRESH');
      }

      final res = await api.refresh(refresh);
      final data = res.data;

      if (data is! Map) {
        throw Exception('BAD_REFRESH_RESPONSE');
      }

      final newToken = (data['token'] ?? '').toString().trim();
      final newRefresh = (data['refreshToken'] ?? '').toString().trim();

      if (newToken.isEmpty || newRefresh.isEmpty) {
        throw Exception('BAD_REFRESH');
      }

      final (_, role) = await jwtStore.read();

      await jwtStore.save(
        token: newToken,
        role: role,
        refreshToken: newRefresh,
      );

      DioClient.setToken(newToken);

      for (final w in _waiters) {
        if (!w.isCompleted) {
          w.complete();
        }
      }
      _waiters.clear();
    } catch (e) {
      for (final w in _waiters) {
        if (!w.isCompleted) {
          w.completeError(e);
        }
      }
      _waiters.clear();
      rethrow;
    } finally {
      _refreshing = false;
    }
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final (token, _) = await jwtStore.read();
    final t = token.trim();

    if (t.isNotEmpty) {
      options.headers['Authorization'] =
          t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode ?? 0;

    // Refresh only on protected-request 401
    if (status != 401 || _isAuthPath(err.requestOptions)) {
      return handler.next(err);
    }

    // Avoid infinite retry loop
    if (err.requestOptions.extra['__retried'] == true) {
      return handler.next(err);
    }

    // If request had no auth header, don't try refresh
    final authHeader =
        (err.requestOptions.headers['Authorization'] ?? '').toString().trim();

    if (authHeader.isEmpty) {
      return handler.next(err);
    }

    try {
      await _refresh();

      final retryReq = err.requestOptions;
      retryReq.extra['__retried'] = true;

      final dio = DioClient.ensure();
      final res = await dio.fetch(retryReq);

      return handler.resolve(res);
    } catch (e) {
      final shouldClear = _shouldClearAfterRefreshFailure(e);

      if (shouldClear) {
        await jwtStore.clear();
        DioClient.clearToken();
      }

      return handler.next(err);
    }
  }

  bool _shouldClearAfterRefreshFailure(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode ?? 0;

      // Refresh token truly rejected by backend
      if (status == 401 || status == 403) {
        return true;
      }

      // timeout / no internet / 500 / backend down:
      // do NOT wipe saved session
      return false;
    }

    final msg = e.toString().toUpperCase();

    return msg.contains('NO_REFRESH') ||
        msg.contains('BAD_REFRESH') ||
        msg.contains('BAD_REFRESH_RESPONSE') ||
        msg.contains('MISSING_TOKENS') ||
        msg.contains('INVALID_REFRESH') ||
        msg.contains('REFRESH TOKEN');
  }
}