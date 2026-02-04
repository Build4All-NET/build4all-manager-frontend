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
}
