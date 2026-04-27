import 'package:dio/dio.dart';
import '../models/project_dto.dart';
import 'package:flutter/foundation.dart';

class ProjectsApi {
  final Dio dio;
  final String baseUrl;

  ProjectsApi({required this.dio, required this.baseUrl});

 Future<ProjectDto> createProject({
  required String token,
  required String projectName,
  String? description,
  bool? active,
  String? projectType,
}) async {
  final url = "$baseUrl/projects";

  final payload = ProjectDto(
    id: 0,
    projectName: projectName,
    description: description,
    active: active ?? false,
    projectType: projectType ?? "ECOMMERCE",
  ).toCreateJson(
    projectName: projectName,
    description: description,
    active: active,
    projectType: projectType,
  );

  try {
    final res = await dio.post(
      url,
      data: payload,
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ),
    );

    return ProjectDto.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    debugPrint('❌ createProject failed');
    debugPrint('url: $url');
    debugPrint('payload: $payload');
    debugPrint('status: ${e.response?.statusCode}');
    debugPrint('response: ${e.response?.data}');
    rethrow;
  }
}

  /// Fetch all possible project types from backend.
  /// Expected response:R
  /// ["ECOMMERCE","GYM","WHOLESALE","MUNICIPALITY","SERVICES","ACTIVITIES"]
  Future<List<String>> fetchProjectTypes({
    required String token,
  }) async {
    final url = "$baseUrl/projects/types";

    final res = await dio.get(
      url,
      options: Options(headers: {
        "Authorization": "Bearer $token",
      }),
    );

    final data = res.data;
    if (data is List) {
      return data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    throw Exception("Unexpected project types response");
  }

  Future<Response> enableProject(int projectId) =>
    dio.put('/projects/$projectId/enable');

Future<Response> disableProject(int projectId) =>
    dio.put('/projects/$projectId/disable');

Future<Response> archiveProject(int projectId) =>
    dio.put('/projects/$projectId/archive');
}