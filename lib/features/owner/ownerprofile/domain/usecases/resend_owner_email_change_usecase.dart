import '../repositories/i_owner_profile_repository.dart';

class ResendOwnerEmailChangeUseCase {
  final IOwnerProfileRepository repo;
  ResendOwnerEmailChangeUseCase(this.repo);

  Future<void> call() => repo.resendEmailChange();
}