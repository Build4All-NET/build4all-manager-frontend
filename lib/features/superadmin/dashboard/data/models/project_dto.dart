import '../../domain/entities/project_summary.dart';

class ProjectDto {
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

  ProjectDto({
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

  factory ProjectDto.fromJson(Map<String, dynamic> j) => ProjectDto(
        id: (j['id'] as num).toInt(),
        name: j['projectName']?.toString() ?? '',
        description: j['description']?.toString(),
        active: (j['active'] ?? false) as bool,
        archived: (j['archived'] ?? false) as bool,
        projectType: j['projectType']?.toString(),
        displayTitle: j['displayTitle']?.toString(),
        displayDescription: j['displayDescription']?.toString(),
        iconName: j['iconName']?.toString(),
        cardColor: j['cardColor']?.toString(),
        displayOrder: j['displayOrder'] != null
            ? (j['displayOrder'] as num).toInt()
            : null,
        createdAt: DateTime.parse(j['createdAt'].toString()),
        updatedAt: DateTime.parse(j['updatedAt'].toString()),
      );

  ProjectSummary toEntity() => ProjectSummary(
        id: id,
        name: name,
        description: description,
        active: active,
        archived: archived,
        projectType: projectType,
        displayTitle: displayTitle,
        displayDescription: displayDescription,
        iconName: iconName,
        cardColor: cardColor,
        displayOrder: displayOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
