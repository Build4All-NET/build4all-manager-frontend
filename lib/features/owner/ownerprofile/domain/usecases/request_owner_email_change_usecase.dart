import '../repositories/i_owner_profile_repository.dart';

class RequestOwnerEmailChangeUseCase {
  final IOwnerProfileRepository repo;
  RequestOwnerEmailChangeUseCase(this.repo);

  Future<void> call(String newEmail) => repo.requestEmailChange(newEmail);
}