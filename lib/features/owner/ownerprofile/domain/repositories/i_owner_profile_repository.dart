import '../entities/owner_profile.dart';

abstract class IOwnerProfileRepository {
  Future<OwnerProfile> getMe();
  Future<OwnerProfile> getById(int adminId);

  Future<OwnerProfile> updateMe(Map<String, dynamic> body);

  // NEW
  Future<void> requestEmailChange(String newEmail);
  Future<void> verifyEmailChange(String code);
  Future<void> resendEmailChange();

    Future<void> requestPhoneChange(String newPhone);
  Future<void> verifyPhoneChange(String code);
  Future<void> resendPhoneChange();
}