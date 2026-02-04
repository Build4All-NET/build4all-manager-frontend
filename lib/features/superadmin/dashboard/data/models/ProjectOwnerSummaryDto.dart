class ProjectOwnerSummaryDto {
  final int adminId;
  final String fullName;
  final String email;
  final int appsCount;
  final String? phoneNumber;

  ProjectOwnerSummaryDto({
    required this.adminId,
    required this.fullName,
    required this.email,
    required this.appsCount,
    this.phoneNumber,
  });

  factory ProjectOwnerSummaryDto.fromJson(Map<String, dynamic> json) {
    String? _cleanPhone(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty || s == '_' || s.toLowerCase() == 'null') return null;
      return s;
    }

    return ProjectOwnerSummaryDto(
      adminId: (json['adminId'] as num).toInt(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      appsCount: (json['appsCount'] as num?)?.toInt() ?? 0,
      phoneNumber: _cleanPhone(json['phoneNumber']),
    );
  }
}
