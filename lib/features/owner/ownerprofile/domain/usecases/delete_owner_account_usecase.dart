import '../repositories/i_owner_profile_repository.dart';

class DeleteOwnerAccountUseCase {
  final IOwnerProfileRepository repository;

  DeleteOwnerAccountUseCase(this.repository);

  Future<void> call({required String password}) {
    return repository.deleteMyAccount(password: password);
  }
}