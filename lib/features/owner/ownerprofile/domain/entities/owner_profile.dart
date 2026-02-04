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
    this.createdAt,
    this.updatedAt,
    this.phoneNumber,
  });

  String get fullName =>
      [firstName, lastName].where((e) => e.isNotEmpty).join(' ');

      
}
