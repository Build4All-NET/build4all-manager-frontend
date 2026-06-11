class OwnerProfileDto {
  final int adminId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final int? businessId;
  final bool? notifyItemUpdates;
  final bool? notifyUserFeedback;
  final String? phoneNumber;

  final int? countryId;
  final String? countryName;
  final String? countryIso2Code;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  OwnerProfileDto({
    required this.adminId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.businessId,
    this.notifyItemUpdates,
    this.notifyUserFeedback,
    this.phoneNumber,
    this.countryId,
    this.countryName,
    this.countryIso2Code,
    this.createdAt,
    this.updatedAt,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory OwnerProfileDto.fromJson(Map<String, dynamic> j) {
    return OwnerProfileDto(
      adminId: _toInt(j['adminId'] ?? j['id']),
      username: (j['username'] ?? '').toString(),
      firstName: (j['firstName'] ?? '').toString(),
      lastName: (j['lastName'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      role: (j['role'] ?? '').toString(),
      businessId: j['businessId'] == null ? null : _toInt(j['businessId']),
      notifyItemUpdates: j['notifyItemUpdates'] as bool?,
      notifyUserFeedback: j['notifyUserFeedback'] as bool?,
      phoneNumber: (j['phoneNumber'] ?? '').toString(),

      // Country returned from backend profile API.
      countryId: j['countryId'] == null ? null : _toInt(j['countryId']),
      countryName: (j['countryName'] ?? '').toString(),
      countryIso2Code: (j['countryIso2Code'] ?? '').toString(),

      createdAt: _toDate(j['createdAt']),
      updatedAt: _toDate(j['updatedAt']),
    );
  }
}