class AdminProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final bool notifyItemUpdates;
  final bool notifyUserFeedback;

  const AdminProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.notifyItemUpdates,
    required this.notifyUserFeedback,
  });

  AdminProfile copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phoneNumber,
    bool? notifyItemUpdates,
    bool? notifyUserFeedback,
  }) {
    return AdminProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notifyItemUpdates: notifyItemUpdates ?? this.notifyItemUpdates,
      notifyUserFeedback: notifyUserFeedback ?? this.notifyUserFeedback,
    );
  }
}
