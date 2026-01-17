import 'package:dio/dio.dart';
import '../models/owner_ai_status_dto.dart';

class SuperAdminAiApi {
  final Dio dio;
  SuperAdminAiApi(this.dio);

  Future<OwnerAiStatusDto> getOwnerAi(int ownerId) async {
    final r = await dio.get('/admin/super/owners/$ownerId/ai');
    return OwnerAiStatusDto.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OwnerAiStatusDto> toggleOwnerAi(int ownerId, bool enabled) async {
    final r = await dio.patch(
      '/admin/super/owners/$ownerId/ai',
      data: {'enabled': enabled},
    );

    // backend returns { message, ownerId, aiEnabled }
    return OwnerAiStatusDto.fromJson(r.data as Map<String, dynamic>);
  }
}
