import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/app_config_dto.dart';
import '../models/app_request_dto.dart';
import '../models/owner_project_dto.dart';
import '../../domain/entities/app_request.dart';

class OwnerApi {
  final Dio dio;
  OwnerApi(this.dio);

  Future<AppConfigDto> getAppConfig() async {
    try {
      final r = await dio.get('/public/app-config'); // => /api/public/app-config
      return AppConfigDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (_) {
      return AppConfigDto(ownerProjectLinkId: null, wsPath: '');
    }
  }

  // ✅ ownerId removed
  Future<List<AppRequestDto>> getMyRequests() async {
    final r = await dio.get('/owner/app-requests');
    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(AppRequestDto.fromJson).toList();
  }

  // ✅ ownerId removed
  Future<List<OwnerProjectDto>> getMyApps() async {
    final r = await dio.get('/owner/my-apps');

    if (kDebugMode) {
      debugPrint('MY_APPS RAW => ${r.data}');
    }

    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(OwnerProjectDto.fromJson).toList();
  }

  Future<void> deleteApp({required int linkId}) async {
    await dio.delete('/owner/apps/$linkId'); // matches backend: DELETE /api/owner/apps/{linkId}
  }

  Future<void> rebuildAndroid({required int linkId}) async {
    await dio.post('/owner/apps/$linkId/rebuild-bundle');
  }

  Future<void> rebuildIos({required int linkId}) async {
    await dio.post('/owner/apps/$linkId/rebuild-ios');
  }

  Future<void> rebuildBoth({required int linkId}) async {
    await dio.post('/owner/apps/$linkId/rebuild-both');
  }

  // ✅ If you still want a “recent requests” helper, do it client-side (cleanest)
  Future<List<AppRequest>> getRecentRequests({int limit = 5}) async {
    final all = await getMyRequests();
    final entities = all.map((e) => e.toEntity()).toList();
    entities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entities.take(limit).toList();
  }
}