class BackendProject {
  final int id;
  final String name;
  final String description;
  final bool active;
  final String? projectType;

  // Display fields set by Super Admin
  final String? displayTitle;
  final String? displayDescription;
  final String? iconName;
  final String? cardColor;
  final int displayOrder;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BackendProject({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    this.projectType,
    this.displayTitle,
    this.displayDescription,
    this.iconName,
    this.cardColor,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });
}
