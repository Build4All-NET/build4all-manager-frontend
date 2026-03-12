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
      final r = await dio.get('/public/app-config');
      return AppConfigDto.fromJson(r.data as Map<String, dynamic>);
    } on DioException {
      return AppConfigDto(ownerProjectLinkId: null, wsPath: '');
    }
  }

  Future<List<AppRequestDto>> getMyRequests() async {
    final r = await dio.get('/owner/app-requests');
    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(AppRequestDto.fromJson).toList();
  }

  Future<List<OwnerProjectDto>> getMyApps() async {
    final r = await dio.get('/owner/my-apps');

    final list = (r.data as List).cast<Map<String, dynamic>>();

    if (kDebugMode) {
      debugPrint('MY_APPS count => ${list.length}');
    }

    return list.map(OwnerProjectDto.fromJson).toList();
  }

  Future<void> deleteApp({required int linkId}) async {
    await dio.delete('/owner/apps/$linkId');
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

  Future<List<AppRequest>> getRecentRequests({int limit = 5}) async {
    final all = await getMyRequests();
    final entities = all.map((e) => e.toEntity()).toList();
    entities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entities.take(limit).toList();
  }
}