class OwnerProfile {
  final int adminId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final int? businessId;
  final bool notifyItemUpdates;
  final bool notifyUserFeedback;
  final String? phoneNumber;

  final int? countryId;
  final String? countryName;
  final String? countryIso2Code;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OwnerProfile({
    required this.adminId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.businessId,
    required this.notifyItemUpdates,
    required this.notifyUserFeedback,
    this.phoneNumber,
    this.countryId,
    this.countryName,
    this.countryIso2Code,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName =>
      [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
}