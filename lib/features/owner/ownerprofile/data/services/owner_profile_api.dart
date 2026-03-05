import 'package:dio/dio.dart';
import '../models/owner_profile_dto.dart';

class OwnerProfileApi {
  final Dio dio;
  OwnerProfileApi(this.dio);

  Future<OwnerProfileDto> getMe() async {
    final res = await dio.get('/admin/users/me');
    return OwnerProfileDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OwnerProfileDto> getById(int adminId) async {
    final res = await dio.get('/admin/users/$adminId');
    return OwnerProfileDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OwnerProfileDto> updateMe(Map<String, dynamic> body) async {
    final res = await dio.patch('/admin/users/me', data: body);
    final raw = res.data;

    if (raw is Map && raw['data'] is Map) {
      return OwnerProfileDto.fromJson(Map<String, dynamic>.from(raw['data']));
    }
    return OwnerProfileDto.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  // ✅ NEW: email change OTP flow
  Future<void> requestEmailChange(String newEmail) async {
    await dio.post('/admin/users/me/request-email-change', data: {
      'newEmail': newEmail,
    });
  }

  Future<void> verifyEmailChange(String code) async {
    await dio.post('/admin/users/me/verify-email-change', data: {
      'code': code,
    });
  }

  Future<void> resendEmailChange() async {
    await dio.post('/admin/users/me/resend-email-change');
  }
}