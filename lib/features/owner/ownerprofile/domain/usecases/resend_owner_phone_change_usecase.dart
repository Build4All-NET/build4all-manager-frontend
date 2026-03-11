import '../repositories/i_owner_profile_repository.dart';

class ResendOwnerPhoneChangeUseCase {
  final IOwnerProfileRepository repo;
  ResendOwnerPhoneChangeUseCase(this.repo);

  Future<void> call() => repo.resendPhoneChange();
}