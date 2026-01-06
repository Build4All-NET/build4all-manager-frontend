class ProjectOwnerSummaryDto {
  final int adminId;
  final String fullName;
  final String email;
  final int appsCount;

  ProjectOwnerSummaryDto({
    required this.adminId,
    required this.fullName,
    required this.email,
    required this.appsCount,
  });

  factory ProjectOwnerSummaryDto.fromJson(Map<String, dynamic> json) {
    return ProjectOwnerSummaryDto(
      adminId: (json['adminId'] as num).toInt(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      appsCount: (json['appsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
