import 'package:dio/dio.dart';
import 'package:build4all_manager/core/network/api_config.dart';
import 'package:build4all_manager/core/network/globals.dart' as g;
import 'package:build4all_manager/core/network/api_client.dart';

class DioClient {
  /// Call once in main() BEFORE runApp()
  static Future<void> init() async {
    final cfg = await ApiConfig.load();

    // baseUrl: http://host:8080/api
    g.appServerRoot = cfg.baseUrl;

    final client = ApiClient(cfg);
    g.appDio = client.dio;
  }

  static Dio ensure() {
    final dio = g.appDio;
    if (dio == null) {
      throw StateError('Dio not initialized. Call DioClient.init() in main().');
    }
    return dio;
  }

  /// Optional manual update (interceptor also reads from storage per-request)
  static void setToken(String token) {
    ensure().options.headers['Authorization'] = 'Bearer ${token.trim()}';
    g.authToken = token.trim();
  }

  static void clearToken() {
    ensure().options.headers.remove('Authorization');
    g.authToken = null;
  }
}
