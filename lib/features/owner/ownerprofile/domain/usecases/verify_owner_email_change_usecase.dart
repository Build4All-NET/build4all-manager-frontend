import '../repositories/i_owner_profile_repository.dart';

class VerifyOwnerEmailChangeUseCase {
  final IOwnerProfileRepository repo;
  VerifyOwnerEmailChangeUseCase(this.repo);

  Future<void> call(String code) => repo.verifyEmailChange(code);
}