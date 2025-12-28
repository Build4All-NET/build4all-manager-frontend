import '../../domain/entities/project.dart';

abstract class CreateProjectEvent {}

class CreateProjectSubmitted extends CreateProjectEvent {
  final String projectName;
  final String? description;
  final bool active;
  final ProjectType projectType;

  CreateProjectSubmitted({
    required this.projectName,
    required this.description,
    required this.active,
    required this.projectType,
  });
}

class CreateProjectReset extends CreateProjectEvent {}
