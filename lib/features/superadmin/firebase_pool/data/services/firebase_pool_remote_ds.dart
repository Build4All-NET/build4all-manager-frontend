import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:dio/dio.dart';

import '../models/firebase_project_account_model.dart';

class FirebasePoolRemoteDs {
  final Dio dio;

  FirebasePoolRemoteDs({Dio? dio}) : dio = dio ?? DioClient.ensure();

  Future<List<FirebaseProjectAccountModel>> getAll() async {
    final res = await dio.get('/superadmin/firebase-pool');
    final data = res.data;
    final list = (data is Map ? (data['data'] ?? data['content']) : null);
    if (list is List) {
      return list
          .map((e) => FirebaseProjectAccountModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    return [];
  }

  Future<FirebaseProjectAccountModel> create({
    required String firebaseProjectId,
    required String displayName,
    required String serviceAccountCredentialsJson,
    int priority = 10,
    int maxAndroidApps = 30,
    int maxIosApps = 30,
    bool isDefault = false,
  }) async {
    final res = await dio.post(
      '/superadmin/firebase-pool',
      data: {
        'firebaseProjectId': firebaseProjectId.trim(),
        'displayName': displayName.trim(),
        'serviceAccountCredentialsJson': serviceAccountCredentialsJson.trim(),
        'priority': priority,
        'maxAndroidApps': maxAndroidApps,
        'maxIosApps': maxIosApps,
        'isDefault': isDefault,
      },
    );
    return _extractAccount(res.data);
  }

  Future<FirebaseProjectAccountModel> update(
    int id, {
    String? displayName,
    String? serviceAccountCredentialsJson,
    int? priority,
    int? maxAndroidApps,
    int? maxIosApps,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName.trim();
    if (serviceAccountCredentialsJson != null &&
        serviceAccountCredentialsJson.trim().isNotEmpty) {
      body['serviceAccountCredentialsJson'] =
          serviceAccountCredentialsJson.trim();
    }
    if (priority != null) body['priority'] = priority;
    if (maxAndroidApps != null) body['maxAndroidApps'] = maxAndroidApps;
    if (maxIosApps != null) body['maxIosApps'] = maxIosApps;
    if (isDefault != null) body['isDefault'] = isDefault;
    final res = await dio.put('/superadmin/firebase-pool/$id', data: body);
    return _extractAccount(res.data);
  }

  Future<void> enable(int id) async {
    await dio.post('/superadmin/firebase-pool/$id/enable');
  }

  Future<void> disable(int id) async {
    await dio.post('/superadmin/firebase-pool/$id/disable');
  }

  Future<void> setDefault(int id) async {
    await dio.post('/superadmin/firebase-pool/$id/set-default');
  }

  FirebaseProjectAccountModel _extractAccount(dynamic data) {
    final obj = data is Map ? (data['data'] ?? data) : data;
    return FirebaseProjectAccountModel.fromJson(
      Map<String, dynamic>.from(obj as Map),
    );
  }
}
