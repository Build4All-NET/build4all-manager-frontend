import '../entities/owner_ai_status.dart';
import '../repositories/superadmin_ai_repository.dart';

class ToggleOwnerAi {
  final SuperAdminAiRepository repo;
  ToggleOwnerAi(this.repo);

  Future<OwnerAiStatus> call({required int ownerId, required bool enabled}) {
    return repo.setOwnerAiStatus(ownerId: ownerId, enabled: enabled);
  }
}
