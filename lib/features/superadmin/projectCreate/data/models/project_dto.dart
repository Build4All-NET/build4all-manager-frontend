class ProjectDto {
  final int id;
  final String projectName;
  final String? description;
  final bool active;
  final String projectType; // "ECOMMERCE" | "SERVICES" | "ACTIVITIES"

  ProjectDto({
    required this.id,
    required this.projectName,
    required this.description,
    required this.active,
    required this.projectType,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) => int.tryParse((v ?? '').toString()) ?? 0;

    return ProjectDto(
      id: toInt(j['id']),
      projectName: (j['projectName'] ?? '').toString(),
      description: j['description']?.toString(),
      active: j['active'] == true,
      projectType: (j['projectType'] ?? 'ECOMMERCE').toString(),
    );
  }

  Map<String, dynamic> toCreateJson({
    required String projectName,
    String? description,
    bool? active,
    String? projectType,
  }) {
    return {
      "projectName": projectName,
      "description": description,
      if (active != null) "active": active,
      if (projectType != null) "projectType": projectType,
    };
  }
}
