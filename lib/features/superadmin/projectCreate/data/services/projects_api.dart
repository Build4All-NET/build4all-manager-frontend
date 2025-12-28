import 'package:dio/dio.dart';
import '../models/project_dto.dart';

class ProjectsApi {
  final Dio dio;
  final String baseUrl;

  ProjectsApi({required this.dio, required this.baseUrl});

  Future<ProjectDto> createProject({
    required String token,
    required String projectName,
    String? description,
    bool? active,
    String? projectType, // "ECOMMERCE" | "SERVICES" | "ACTIVITIES"
  }) async {
    final url = "$baseUrl/projects";

    final payload = ProjectDto(
      id: 0,
      projectName: projectName,
      description: description,
      active: active ?? true,
      projectType: projectType ?? "ECOMMERCE",
    ).toCreateJson(
      projectName: projectName,
      description: description,
      active: active,
      projectType: projectType,
    );

    final res = await dio.post(
      url,
      data: payload,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    return ProjectDto.fromJson(res.data as Map<String, dynamic>);
  }
}
