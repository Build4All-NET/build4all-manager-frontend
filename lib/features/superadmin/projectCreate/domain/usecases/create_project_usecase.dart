import '../entities/project.dart';
import '../repositories/projects_repository.dart';

class CreateProjectUseCase {
  final ProjectsRepository repo;

  CreateProjectUseCase(this.repo);

  Future<Project> call({
    required String token,
    required String projectName,
    String? description,
    bool? active,
    required String projectType,
    String? displayTitle,
    String? displayDescription,
    String? iconName,
    String? cardColor,
    int? displayOrder,
  }) {
    return repo.createProject(
      token: token,
      projectName: projectName,
      description: description,
      active: active,
      projectType: projectType,
      displayTitle: displayTitle,
      displayDescription: displayDescription,
      iconName: iconName,
      cardColor: cardColor,
      displayOrder: displayOrder,
    );
  }
}