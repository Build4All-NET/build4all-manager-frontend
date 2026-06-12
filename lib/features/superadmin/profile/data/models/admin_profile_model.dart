import '../../domain/entities/admin_profile.dart';

class AdminProfileModel extends AdminProfile {
  const AdminProfileModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.username,
    required super.email,
    required super.phoneNumber,
    required super.notifyItemUpdates,
    required super.notifyUserFeedback,
  });

  factory AdminProfileModel.fromJson(Map<String, dynamic> j) {
    return AdminProfileModel(
      id: (j['id'] ?? 0) as int,
      firstName: (j['firstName'] ?? '').toString(),
      lastName: (j['lastName'] ?? '').toString(),
      username: (j['username'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phoneNumber: (j['phoneNumber'] ?? '').toString(),
      notifyItemUpdates: (j['notifyItemUpdates'] ?? false) as bool,
      notifyUserFeedback: (j['notifyUserFeedback'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toProfileUpdateBody() => {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'phoneNumber': phoneNumber,
      };

  Map<String, dynamic> toNotificationsUpdateBody() => {
        'notifyItemUpdates': notifyItemUpdates,
        'notifyUserFeedback': notifyUserFeedback,
      };
}
