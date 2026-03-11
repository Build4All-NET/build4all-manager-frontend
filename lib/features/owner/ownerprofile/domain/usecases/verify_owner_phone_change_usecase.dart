import '../repositories/i_owner_profile_repository.dart';

class VerifyOwnerPhoneChangeUseCase {
  final IOwnerProfileRepository repo;
  VerifyOwnerPhoneChangeUseCase(this.repo);

  Future<void> call(String code) => repo.verifyPhoneChange(code);
}