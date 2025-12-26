import '../../domain/entities/backend_project.dart';

class BackendProjectDto {
  final int id;
  final String projectName;
  final String description;
  final bool active;

  // ✅ NEW
  final String? projectType; // e.g. "ECOMMERCE", "ACTIVITIES", ...

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BackendProjectDto({
    required this.id,
    required this.projectName,
    required this.description,
    required this.active,
    this.projectType,
    this.createdAt,
    this.updatedAt,
  });

  factory BackendProjectDto.fromJson(Map<String, dynamic> j) {
    DateTime? _p(String? iso) =>
        (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);

    return BackendProjectDto(
      id: (j['id'] as num).toInt(),
      projectName: (j['projectName'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      active: j['active'] == true,

      // ✅ NEW
      projectType: j['projectType']?.toString(),

      createdAt: _p(j['createdAt']?.toString()),
      updatedAt: _p(j['updatedAt']?.toString()),
    );
  }

  BackendProject toEntity() => BackendProject(
        id: id,
        name: projectName,
        description: description,
        active: active,

        // ✅ NEW
        projectType: projectType,

        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
