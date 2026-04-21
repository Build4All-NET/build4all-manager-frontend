import 'package:build4all_manager/features/owner/ownerhome/data/models/backend_project_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OwnerProjectsApi {
  final Dio dio;
  OwnerProjectsApi(this.dio);

  Future<List<BackendProjectDto>> fetchProjects() async {
    final res = await dio.get('/projects');

    final data = (res.data as List?) ?? const [];

    final list = data
        .map((e) => BackendProjectDto.fromJson(e as Map<String, dynamic>))
        .toList();

    if (kDebugMode) {
      debugPrint('PROJECTS_API count => ${list.length}');
      for (final p in list) {
        debugPrint(
          'PROJECT => id=${p.id}, '
          'name=${p.projectName}, '
          'active=${p.active}, '
          'type=${p.projectType}',
        );
      }
    }

    return list;
  }
}