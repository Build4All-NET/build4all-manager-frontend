import '../../domain/entities/backend_project.dart';

class BackendProjectDto {
  final int id;
  final String projectName;
  final String description;
  final bool active;
  final String? projectType;
  final String? displayTitle;
  final String? displayDescription;
  final String? iconName;
  final String? cardColor;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BackendProjectDto({
    required this.id,
    required this.projectName,
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

  factory BackendProjectDto.fromJson(Map<String, dynamic> j) {
    DateTime? p(String? iso) =>
        (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);

    return BackendProjectDto(
      id: (j['id'] as num).toInt(),
      projectName: (j['projectName'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      active: j['active'] == true,
      projectType: j['projectType']?.toString(),
      displayTitle: j['displayTitle']?.toString(),
      displayDescription: j['displayDescription']?.toString(),
      iconName: j['iconName']?.toString(),
      cardColor: j['cardColor']?.toString(),
      displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
      createdAt: p(j['createdAt']?.toString()),
      updatedAt: p(j['updatedAt']?.toString()),
    );
  }

  BackendProject toEntity() => BackendProject(
        id: id,
        name: projectName,
        description: description,
        active: active,
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
