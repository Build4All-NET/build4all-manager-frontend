import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:dio/dio.dart';

import '../models/app_publish_request_admin_model.dart';
import '../models/publisher_profile_model.dart';

class PublishAdminRemoteDs {
  final Dio dio;

  PublishAdminRemoteDs({Dio? dio}) : dio = dio ?? DioClient.ensure();

  Future<List<AppPublishRequestAdminModel>> getRequests(String status) async {
    final res = await dio.get(
      '/superadmin/publish',
      queryParameters: {'status': status},
    );

    final data = res.data;
    final list = (data is Map ? data['data'] : null);

    if (list is List) {
      return list
          .map((e) => AppPublishRequestAdminModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    return [];
  }

  Future<void> approve(int requestId, String? notes) async {
    await dio.post(
      '/superadmin/publish/$requestId/approve',
      data:
          notes == null || notes.trim().isEmpty ? {} : {'notes': notes.trim()},
    );
  }

  Future<void> reject(int requestId, String? notes) async {
    await dio.post(
      '/superadmin/publish/$requestId/reject',
      data:
          notes == null || notes.trim().isEmpty ? {} : {'notes': notes.trim()},
    );
  }

  Future<List<PublisherProfileModel>> getProfiles() async {
    final res = await dio.get('/superadmin/publisher-profiles');
    final data = res.data;
    final list = (data is Map ? data['data'] : null);

    if (list is List) {
      return list
          .map((e) => PublisherProfileModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    return [];
  }

  Future<PublisherProfileModel> upsertProfile({
    required String store,
    required String developerName,
    required String developerEmail,
    required String privacyPolicyUrl,
  }) async {
    final res = await dio.post(
      '/superadmin/publisher-profiles/upsert',
      data: {
        'store': store,
        'developerName': developerName.trim(),
        'developerEmail': developerEmail.trim(),
        'privacyPolicyUrl': privacyPolicyUrl.trim(),
      },
    );

    final data = res.data;
    final obj = (data is Map ? data['data'] : null);

    if (obj is Map) {
      return PublisherProfileModel.fromJson(Map<String, dynamic>.from(obj));
    }
    throw Exception('Invalid response');
  }
}
