import 'package:shared_preferences/shared_preferences.dart';

class JwtLocalDataSource {
  static const _kToken = 'auth_jwt';
  static const _kRole = 'auth_role';
  static const _kRefresh = 'auth_refresh'; // ✅ NEW

  Future<void> save({
    required String token,
    required String role,
    required String refreshToken, // ✅ NEW
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token.trim());
    await p.setString(_kRole, role.trim());
    await p.setString(_kRefresh, refreshToken.trim());
  }

  // THIS is what your repo expects
  Future<(String token, String role)> read() async {
    final p = await SharedPreferences.getInstance();
    return (
      p.getString(_kToken) ?? '',
      p.getString(_kRole) ?? '',
    );
  }

  //  NEW
  Future<String?> readRefreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kRole);
    await p.remove(_kRefresh);
  }
}