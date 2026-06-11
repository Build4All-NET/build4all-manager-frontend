import '../../domain/entities/owner_profile.dart';
import '../../domain/repositories/i_owner_profile_repository.dart';
import '../models/owner_profile_dto.dart';
import '../services/owner_profile_api.dart';

class OwnerProfileRepositoryImpl implements IOwnerProfileRepository {
  final OwnerProfileApi api;

  OwnerProfileRepositoryImpl(this.api);

  OwnerProfile _map(OwnerProfileDto d) => OwnerProfile(
        adminId: d.adminId,
        username: d.username,
        firstName: d.firstName,
        lastName: d.lastName,
        email: d.email,
        role: d.role,
        businessId: d.businessId,
        notifyItemUpdates: d.notifyItemUpdates ?? true,
        notifyUserFeedback: d.notifyUserFeedback ?? true,
        phoneNumber: d.phoneNumber,

        // Country mapping for OWNER profile.
        countryId: d.countryId,
        countryName: d.countryName,
        countryIso2Code: d.countryIso2Code,

        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
      );

  @override
  Future<OwnerProfile> getMe() async => _map(await api.getMe());

  @override
  Future<OwnerProfile> getById(int adminId) async =>
      _map(await api.getById(adminId));

  @override
  Future<OwnerProfile> updateMe(Map<String, dynamic> body) async =>
      _map(await api.updateMe(body));

  @override
  Future<void> requestEmailChange(String newEmail) =>
      api.requestEmailChange(newEmail);

  @override
  Future<void> verifyEmailChange(String code) =>
      api.verifyEmailChange(code);

  @override
  Future<void> resendEmailChange() =>
      api.resendEmailChange();

  @override
  Future<void> requestPhoneChange(String newPhone) =>
      api.requestPhoneChange(newPhone);

  @override
  Future<void> verifyPhoneChange(String code) =>
      api.verifyPhoneChange(code);

  @override
  Future<void> resendPhoneChange() =>
      api.resendPhoneChange();

  @override
  Future<void> deleteMyAccount({required String password}) {
    return api.deleteMyAccount(password: password);
  }
}