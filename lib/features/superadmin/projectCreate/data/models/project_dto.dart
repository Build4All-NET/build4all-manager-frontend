class ProjectDto {
  final int id;
  final String projectName;
  final String? description;
  final bool active;
  final String projectType;
  final String? displayTitle;
  final String? displayDescription;
  final String? iconName;
  final String? cardColor;
  final int displayOrder;

  ProjectDto({
    required this.id,
    required this.projectName,
    required this.description,
    required this.active,
    required this.projectType,
    this.displayTitle,
    this.displayDescription,
    this.iconName,
    this.cardColor,
    this.displayOrder = 0,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> j) {
    int toInt(dynamic v) => int.tryParse((v ?? '').toString()) ?? 0;

    return ProjectDto(
      id: toInt(j['id']),
      projectName: (j['projectName'] ?? '').toString(),
      description: j['description']?.toString(),
      active: j['active'] == true,
      projectType: (j['projectType'] ?? 'ECOMMERCE').toString(),
      displayTitle: j['displayTitle']?.toString(),
      displayDescription: j['displayDescription']?.toString(),
      iconName: j['iconName']?.toString(),
      cardColor: j['cardColor']?.toString(),
      displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson({
    required String projectName,
    String? description,
    bool? active,
    String? projectType,
    String? displayTitle,
    String? displayDescription,
    String? iconName,
    String? cardColor,
    int? displayOrder,
  }) {
    return {
      'projectName': projectName,
      if (description != null) 'description': description,
      if (active != null) 'active': active,
      if (projectType != null) 'projectType': projectType,
      if (displayTitle != null) 'displayTitle': displayTitle,
      if (displayDescription != null) 'displayDescription': displayDescription,
      if (iconName != null) 'iconName': iconName,
      if (cardColor != null) 'cardColor': cardColor,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };
  }
}
