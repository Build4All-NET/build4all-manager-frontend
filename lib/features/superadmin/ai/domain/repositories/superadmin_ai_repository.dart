import '../entities/owner_ai_status.dart';

abstract class SuperAdminAiRepository {
  Future<OwnerAiStatus> getOwnerAiStatus({required int ownerId});
  Future<OwnerAiStatus> setOwnerAiStatus({
    required int ownerId,
    required bool enabled,
  });
}
