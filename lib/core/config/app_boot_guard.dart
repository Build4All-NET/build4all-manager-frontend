import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBootGuard {

  static const String authEpoch = 'manager-2026-02-19-v1';

  static const _kEpoch = 'auth_epoch';
  static const _kApiRoot = 'auth_api_root';

  static Future<void> run({required String currentApiBaseUrl}) async {
    final sp = await SharedPreferences.getInstance();

    final oldEpoch = (sp.getString(_kEpoch) ?? '').trim();
    final oldApi = (sp.getString(_kApiRoot) ?? '').trim();

    final epochChanged = oldEpoch != authEpoch;


    final apiChanged =
        oldApi.isNotEmpty && oldApi != currentApiBaseUrl.trim();

    if (epochChanged || apiChanged) {
    
      await JwtLocalDataSource().clear();
    }

    await sp.setString(_kEpoch, authEpoch);
    await sp.setString(_kApiRoot, currentApiBaseUrl.trim());
  }
}
