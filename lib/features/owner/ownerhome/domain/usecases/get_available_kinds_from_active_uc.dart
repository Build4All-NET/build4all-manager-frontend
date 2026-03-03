// lib/features/owner/ownerhome/domain/usecases/get_available_kinds_from_active_uc.dart
// ✅ FIX: Home availability must be based on *owner apps* (GET /owner/my-apps),
// not the global platform projects list (GET /projects).

import '../../../common/domain/entities/owner_project.dart';
import '../../../common/domain/repositories/i_owner_repository.dart';

class _KindMapper {
  static String? map(OwnerProject p) {
    final raw = '${p.slug} ${p.projectName}'.toLowerCase();

    if (raw.contains('ecom') || raw.contains('shop')) return 'ecommerce';
    if (raw.contains('activ')) return 'activities';
    if (raw.contains('gym') || raw.contains('fitness')) return 'gym';
    if (raw.contains('service')) return 'services';

    return null;
  }
}

class GetAvailableKindsFromActiveUc {
  final IOwnerRepository repo;
  const GetAvailableKindsFromActiveUc(this.repo);

  /// ✅ kind -> real DB projectId (NOT linkId)
  /// ✅ Uses only the owner's current apps.
  /// ✅ When an app is deleted, it disappears from /owner/my-apps => kind removed.
  Future<Map<String, int>> call() async {
    final list = await repo.getMyApps();

    final map = <String, int>{};
    for (final p in list) {
      final k = _KindMapper.map(p);
      if (k == null) continue;

      map.putIfAbsent(k, () => p.projectId);
    }

    return map;
  }
}