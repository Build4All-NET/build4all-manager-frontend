import 'package:dio/dio.dart';
import '../models/owner_profile_dto.dart';

class OwnerProfileApi {
  final Dio dio;
  OwnerProfileApi(this.dio);

  Future<OwnerProfileDto> getMe() async {
    final res = await dio.get('/admin/users/me');
    print('RAW /admin/users/me => ${res.data}');
    return OwnerProfileDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OwnerProfileDto> getById(int adminId) async {
    final res = await dio.get('/admin/users/$adminId');
    return OwnerProfileDto.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH /admin/users/me
  /// Backend might return:
  /// { "message": "...", "data": { ...dto... } }
  /// or directly { ...dto... }
  Future<OwnerProfileDto> updateMe(Map<String, dynamic> body) async {
    final res = await dio.patch('/admin/users/me', data: body);

    final raw = res.data;

    if (raw is Map && raw['data'] is Map) {
      return OwnerProfileDto.fromJson(Map<String, dynamic>.from(raw['data']));
    }

    return OwnerProfileDto.fromJson(Map<String, dynamic>.from(raw as Map));
  }
}
