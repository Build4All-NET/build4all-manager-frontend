import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PatStorage {
  static const _key = 'github_pat';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String?> read() async {
    final v = await _storage.read(key: _key);
    return (v == null || v.isEmpty) ? null : v;
  }

  static Future<void> write(String pat) =>
      _storage.write(key: _key, value: pat);

  static Future<void> delete() => _storage.delete(key: _key);
}
