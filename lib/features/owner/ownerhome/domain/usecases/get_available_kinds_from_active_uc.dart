// lib/features/owner/ownerhome/domain/usecases/get_available_kinds_from_active_uc.dart
import '../entities/backend_project.dart';
import '../repositories/i_owner_projects_repository.dart';

class _KindMapper {
  static String? map(BackendProject p) {
    if (!p.active) return null;

    final t = (p.projectType ?? '').toUpperCase().trim();

    switch (t) {
      case 'ACTIVITIES':
      case 'ACTIVITY':
        return 'activities';

      case 'ECOMMERCE':
      case 'E_COMMERCE':
      case 'SHOP':
        return 'ecommerce';

      case 'GYM':
      case 'FITNESS':
        return 'gym';

      case 'SERVICES':
      case 'SERVICE':
        return 'services';

      default:
        return null;
    }
  }
}

class GetAvailableKindsFromActiveUc {
  final IOwnerProjectsRepository repo;
  const GetAvailableKindsFromActiveUc(this.repo);

  /// ✅ kind -> real DB projectId
  /// ✅ ONLY active projects included
  /// ✅ NO fallback default (if all inactive => returns empty map)
  Future<Map<String, int>> call() async {
    final list = await repo.getProjects();

    final map = <String, int>{};

    for (final p in list) {
      final k = _KindMapper.map(p);
      if (k == null) continue;

      // if multiple active projects share same type, keep first one
      map.putIfAbsent(k, () => p.id);
    }

    return map; // ✅ can be empty (this is what you want)
  }
}
