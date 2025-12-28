import '../entities/project.dart';

abstract class ProjectsRepository {
  Future<Project> createProject({
    required String token,
    required String projectName,
    String? description,
    bool? active,
    required ProjectType projectType,
  });
}
