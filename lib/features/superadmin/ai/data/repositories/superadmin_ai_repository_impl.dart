import '../../domain/entities/owner_ai_status.dart';
import '../../domain/repositories/superadmin_ai_repository.dart';
import '../services/superadmin_ai_api.dart';

class SuperAdminAiRepositoryImpl implements SuperAdminAiRepository {
  final SuperAdminAiApi api;
  SuperAdminAiRepositoryImpl(this.api);

  @override
  Future<OwnerAiStatus> getOwnerAiStatus({required int ownerId}) async {
    final dto = await api.getOwnerAi(ownerId);
    return dto.toEntity();
  }

  @override
  Future<OwnerAiStatus> setOwnerAiStatus({
    required int ownerId,
    required bool enabled,
  }) async {
    final dto = await api.toggleOwnerAi(ownerId, enabled);
    return dto.toEntity();
  }
}
