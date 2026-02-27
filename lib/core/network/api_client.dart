import 'package:build4all_manager/core/network/api_config.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:dio/dio.dart';

import 'package:build4all_manager/app/nav_key.dart';
import 'package:build4all_manager/core/network/auth_interceptor.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

class ApiClient {
  final Dio dio;

  ApiClient(ApiConfig config)
      : dio = Dio(
          BaseOptions(
            baseUrl: config.baseUrl, // http://host:8080/api
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // ✅ auto attach token + handle 401 → logout
    dio.interceptors.add(
      AuthInterceptor(
        jwtStore: JwtLocalDataSource(),
        api: AuthApi(dio),
      ),
    );

    // ✅ logs
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer ${token.trim()}';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
