import '../entities/project.dart';

abstract class ProjectsRepository {
  Future<Project> createProject({
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
  });

  Future<List<String>> fetchProjectTypes({
    required String token,
  });
}