import '../entities/owner_ai_status.dart';
import '../repositories/superadmin_ai_repository.dart';

class GetOwnerAiStatus {
  final SuperAdminAiRepository repo;
  GetOwnerAiStatus(this.repo);

  Future<OwnerAiStatus> call({required int ownerId}) {
    return repo.getOwnerAiStatus(ownerId: ownerId);
  }
}
