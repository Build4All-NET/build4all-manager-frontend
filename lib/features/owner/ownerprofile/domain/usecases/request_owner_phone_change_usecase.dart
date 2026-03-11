import '../repositories/i_owner_profile_repository.dart';

class RequestOwnerPhoneChangeUseCase {
  final IOwnerProfileRepository repo;
  RequestOwnerPhoneChangeUseCase(this.repo);

  Future<void> call(String newPhone) => repo.requestPhoneChange(newPhone);
}