abstract class CreateProjectEvent {}

class CreateProjectSubmitted extends CreateProjectEvent {
  final String projectName;
  final String? description;
  final bool active;
  final String projectType;
  final String? displayTitle;
  final String? displayDescription;
  final String? iconName;
  final String? cardColor;
  final int? displayOrder;

  CreateProjectSubmitted({
    required this.projectName,
    required this.description,
    required this.active,
    required this.projectType,
    this.displayTitle,
    this.displayDescription,
    this.iconName,
    this.cardColor,
    this.displayOrder,
  });
}

class CreateProjectReset extends CreateProjectEvent {}