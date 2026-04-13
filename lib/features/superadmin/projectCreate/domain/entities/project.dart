enum ProjectType { ECOMMERCE, GYM, WHOLESALE, MUNICIPALITY, SERVICES, ACTIVITIES }

extension ProjectTypeX on ProjectType {
  String get name {
    switch (this) {
      case ProjectType.ECOMMERCE:
        return "ECOMMERCE";
      case ProjectType.GYM:
        return "GYM";
      case ProjectType.WHOLESALE:
        return "WHOLESALE";
      case ProjectType.MUNICIPALITY:
        return "MUNICIPALITY";
      case ProjectType.SERVICES:
        return "SERVICES";
      case ProjectType.ACTIVITIES:
        return "ACTIVITIES";
    }
  }

  static ProjectType fromName(String raw) {
    final v = raw.trim().toUpperCase();
    if (v == "GYM") return ProjectType.GYM;
    if (v == "WHOLESALE") return ProjectType.WHOLESALE;
    if (v == "MUNICIPALITY") return ProjectType.MUNICIPALITY;
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
  final String projectType;

  const Project({
    required this.id,
    required this.projectName,
    required this.description,
    required this.active,
    required this.projectType,
  });
}
