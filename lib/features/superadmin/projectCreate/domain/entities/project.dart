enum ProjectType { ECOMMERCE, SERVICES, ACTIVITIES }

extension ProjectTypeX on ProjectType {
  String get name {
    switch (this) {
      case ProjectType.ECOMMERCE:
        return "ECOMMERCE";
      case ProjectType.SERVICES:
        return "SERVICES";
      case ProjectType.ACTIVITIES:
        return "ACTIVITIES";
    }
  }

  static ProjectType fromName(String raw) {
    final v = raw.trim().toUpperCase();
    if (v == "SERVICES") return ProjectType.SERVICES;
    if (v == "ACTIVITIES") return ProjectType.ACTIVITIES;
    return ProjectType.ECOMMERCE;
  }
}

class Project {
  final int id;
  final String projectName;
  final String? description;
  final bool active;
  final ProjectType projectType;

  const Project({
    required this.id,
    required this.projectName,
    required this.description,
    required this.active,
    required this.projectType,
  });
}
