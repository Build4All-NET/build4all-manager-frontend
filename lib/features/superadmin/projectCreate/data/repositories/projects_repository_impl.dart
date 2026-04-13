import '../../domain/entities/project.dart';
import '../../domain/repositories/projects_repository.dart';
import '../services/projects_api.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsApi api;

  ProjectsRepositoryImpl(this.api);

  @override
  Future<Project> createProject({
    required String token,
    required String projectName,
    String? description,
    bool? active,
    required String projectType,
  }) async {
    final dto = await api.createProject(
      token: token,
      projectName: projectName,
      description: description,
      active: active,
      projectType: projectType,
    );

    return Project(
      id: dto.id,
      projectName: dto.projectName,
      description: dto.description,
      active: dto.active,
      projectType: dto.projectType,
    );
  }

  @override
  Future<List<String>> fetchProjectTypes({
    required String token,
  }) {
    return api.fetchProjectTypes(token: token);
  }
}