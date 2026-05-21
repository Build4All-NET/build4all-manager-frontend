class ProjectSummary {
  final int id;
  final String name;
  final String? description;
  final bool active;
  final bool archived;
  final String? projectType;
  final String? displayTitle;
  final String? displayDescription;
  final String? iconName;
  final String? cardColor;
  final int? displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectSummary({
    required this.id,
    required this.name,
    required this.active,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.projectType,
    this.displayTitle,
    this.displayDescription,
    this.iconName,
    this.cardColor,
    this.displayOrder,
  });
}
