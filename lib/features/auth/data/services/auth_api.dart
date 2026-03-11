import 'package:dio/dio.dart';
import '../models/login_request_dto.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio); // ✅ inject Dio (no ensure here)

  Future<Response> login(LoginRequestDto body) {
    return _dio.post('/auth/admin/login', data: body.toJson());
  }

  Future<Response> ownerSendOtp({
    required String email,
    required String password,
  }) {
    return _dio.post('/auth/owner/send-verification-email', queryParameters: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> refresh(String refreshToken) {
    return _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
  }

  Future<Response> logout({required String refreshToken}) {
    return _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
  }



  Future<Response> ownerVerifyOtp({
    required String email,
    required String password,
    required String code,
  }) {
    return _dio.post('/auth/owner/verify-email-code', data: {
      'email': email,
      'password': password,
      'code': code,
    });
  }

  Future<Response> ownerCompleteProfile({
    required String registrationToken,
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) {
    return _dio.post('/auth/owner/complete-profile', data: {
      'registrationToken': registrationToken,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
    });
  }
}