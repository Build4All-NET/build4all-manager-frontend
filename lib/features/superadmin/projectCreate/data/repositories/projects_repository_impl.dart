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
    required ProjectType projectType,
  }) async {
    final dto = await api.createProject(
      token: token,
      projectName: projectName,
      description: description,
      active: active,
      projectType: projectType.name, // enum -> "ECOMMERCE"
    );

    return Project(
      id: dto.id,
      projectName: dto.projectName,
      description: dto.description,
      active: dto.active,
      projectType: ProjectTypeX.fromName(dto.projectType),
    );
  }
}
