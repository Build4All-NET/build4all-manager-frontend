import '../../domain/entities/admin_profile.dart';
import '../../domain/repositories/i_admin_repository.dart';
import '../models/admin_profile_model.dart';
import '../services/admin_api.dart';

class AdminRepositoryImpl implements IAdminRepository {
  final AdminApi api;
  AdminRepositoryImpl(this.api);

  @override
  Future<AdminProfile> me() async {
    final r = await api.getMe();
    return AdminProfileModel.fromJson(r.data as Map<String, dynamic>);
    // response shape matches your /me example
  }

  @override
  Future<void> updateProfile(AdminProfile profile) async {
    final model = AdminProfileModel(
      id: profile.id,
      firstName: profile.firstName,
      lastName: profile.lastName,
      username: profile.username,
      email: profile.email,
      notifyItemUpdates: profile.notifyItemUpdates,
      notifyUserFeedback: profile.notifyUserFeedback,
    );
    await api.updateProfile(model.toProfileUpdateBody());
  }

  @override
  Future<void> updatePassword(String currentPassword, String newPassword) =>
      api.updatePassword(
          currentPassword: currentPassword, newPassword: newPassword);

  @override
  Future<void> updateNotifications({
    required bool notifyItemUpdates,
    required bool notifyUserFeedback,
  }) async {
    final body = {
      'notifyItemUpdates': notifyItemUpdates,
      'notifyUserFeedback': notifyUserFeedback,
    };
    await api.updateNotifications(body);
  }
}
