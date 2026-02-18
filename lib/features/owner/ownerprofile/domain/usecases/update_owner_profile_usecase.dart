import '../entities/owner_profile.dart';
import '../repositories/i_owner_profile_repository.dart';

class UpdateOwnerProfileUseCase {
  final IOwnerProfileRepository repo;
  UpdateOwnerProfileUseCase(this.repo);

  Future<OwnerProfile> call(Map<String, dynamic> body) {
    return repo.updateMe(body);
  }
}
