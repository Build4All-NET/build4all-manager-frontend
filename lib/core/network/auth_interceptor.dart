import 'package:dio/dio.dart';

import '../auth/session_manager.dart';
import '../network/dio_client.dart';

class AuthInterceptor extends Interceptor {
  final SessionManager sessionManager;

  AuthInterceptor({
    required this.sessionManager,
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

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final (token, _, _) = await sessionManager.readSession();
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

    if (status != 401 || _isAuthPath(err.requestOptions)) {
      return handler.next(err);
    }

    if (err.requestOptions.extra['__retried'] == true) {
      return handler.next(err);
    }

    final authHeader =
        (err.requestOptions.headers['Authorization'] ?? '').toString().trim();

    if (authHeader.isEmpty) {
      return handler.next(err);
    }

    try {
      final newToken = await sessionManager.refreshTokens();

      if (newToken == null || newToken.trim().isEmpty) {
        return handler.next(err);
      }

      final retryReq = err.requestOptions;
      retryReq.extra['__retried'] = true;
      retryReq.headers['Authorization'] = 'Bearer $newToken';

      final dio = DioClient.ensure();
      final res = await dio.fetch(retryReq);

      return handler.resolve(res);
    } catch (e) {
      final shouldClear =
          sessionManager.shouldClearSessionAfterRefreshFailure(e);

      if (shouldClear) {
        await sessionManager.clearSession();
      }

      return handler.next(err);
    }
  }
}