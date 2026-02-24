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
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return AppConfigDto(ownerProjectLinkId: null, wsPath: '');
      }
      return AppConfigDto(ownerProjectLinkId: null, wsPath: '');
    }
  }

  Future<List<AppRequestDto>> getMyRequests({required int ownerId}) async {
    final r = await dio.get(
      '/owner/app-requests',
      queryParameters: {'ownerId': ownerId},
    );

    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(AppRequestDto.fromJson).toList();
  }

  Future<List<OwnerProjectDto>> getMyApps({required int ownerId}) async {
    final r = await dio.get(
      '/owner/my-apps',
      queryParameters: {'ownerId': ownerId},
    );

    if (kDebugMode) {
      debugPrint('MY_APPS RAW => ${r.data}');
    }

    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map(OwnerProjectDto.fromJson).toList();
  }

  /// ✅ Delete app (owner project link)
Future<void> deleteApp({required int linkId}) async {
  await dio.delete('/owner/apps/$linkId');
}

  // 🔴 REMOVE THIS WRONG METHOD
  // Future<void> rebuildLink(...)

  /// ✅ Rebuild ANDROID only
  Future<void> rebuildAndroid({required int linkId}) async {
    await dio.post('/owner/apps/$linkId/rebuild-bundle');
  }

  /// ✅ Rebuild IOS only
  Future<void> rebuildIos({required int linkId}) async {
    await dio.post('/owner/apps/$linkId/rebuild-ios');
  }

  /// ✅ Rebuild BOTH (optional)
  Future<void> rebuildBoth({required int linkId}) async {
    await dio.post('/owner/apps/$linkId/rebuild-both');
  }

  Future<List<AppRequest>> getRecentRequests(int ownerId,
      {int limit = 5}) async {
    final r = await dio.get(
      '/owner/app-requests',
      queryParameters: {
        'limit': limit,
        'sort': 'createdAt,desc',
        'ownerId': ownerId,
      },
    );

    final list = (r.data as List).cast<Map<String, dynamic>>();
    return list.map((j) => AppRequestDto.fromJson(j).toEntity()).toList();
  }
}
