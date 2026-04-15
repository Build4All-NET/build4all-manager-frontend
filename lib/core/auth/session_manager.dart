import 'dart:convert';

import 'package:dio/dio.dart';

import '../../features/auth/data/datasources/jwt_local_datasource.dart';
import '../../features/auth/data/services/auth_api.dart';
import '../network/dio_client.dart';

class SessionManager {
  final JwtLocalDataSource store;
  final AuthApi authApi;

  Future<String?>? _ongoingRefresh;

  SessionManager({
    required this.store,
    required this.authApi,
  });

  Future<bool> hasSession() async {
    final (token, _) = await store.read();
    final refresh = await store.readRefreshToken();

    return token.trim().isNotEmpty || (refresh?.trim().isNotEmpty ?? false);
  }

  Future<(String token, String role, String refreshToken)> readSession() async {
    final (token, role) = await store.read();
    final refresh = (await store.readRefreshToken()) ?? '';
    return (token.trim(), role.trim(), refresh.trim());
  }

  Future<void> saveSession({
    required String token,
    required String role,
    required String refreshToken,
  }) async {
    await store.save(
      token: token.trim(),
      role: role.trim(),
      refreshToken: refreshToken.trim(),
    );

    if (token.trim().isNotEmpty) {
      DioClient.setToken(token.trim());
    }
  }

  Future<void> clearSession() async {
    await store.clear();
    DioClient.clearToken();
  }

  bool isJwtExpired(String token) {
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

  Future<String?> refreshTokens() async {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }

    _ongoingRefresh = _doRefresh();

    try {
      return await _ongoingRefresh!;
    } finally {
      _ongoingRefresh = null;
    }
  }

  Future<String?> _doRefresh() async {
    final refresh = (await store.readRefreshToken())?.trim() ?? '';
    if (refresh.isEmpty) {
      throw Exception('NO_REFRESH');
    }

    final response = await authApi.refresh(refresh);
    final data = response.data;

    if (data is! Map) {
      throw Exception('BAD_REFRESH_RESPONSE');
    }

    final newToken = (data['token'] ?? '').toString().trim();
    final newRefresh = (data['refreshToken'] ?? '').toString().trim();

    if (newToken.isEmpty || newRefresh.isEmpty) {
      throw Exception('BAD_REFRESH');
    }

    final (_, role) = await store.read();

    await saveSession(
      token: newToken,
      role: role,
      refreshToken: newRefresh,
    );

    return newToken;
  }

  bool shouldClearSessionAfterRefreshFailure(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode ?? 0;

      if (status == 401 || status == 403) {
        return true;
      }

      return false;
    }

    final msg = e.toString().toUpperCase();

    return msg.contains('NO_REFRESH') ||
        msg.contains('BAD_REFRESH') ||
        msg.contains('BAD_REFRESH_RESPONSE') ||
        msg.contains('INVALID_REFRESH') ||
        msg.contains('REFRESH TOKEN');
  }
}