import '../entities/backend_project.dart';
import '../repositories/i_owner_projects_repository.dart';

class _KindMapper {
  static String? map(BackendProject p) {
    // ✅ only active projects count
    if (!p.active) return null;

    final t = (p.projectType ?? '').toUpperCase().trim();

    // ✅ Map backend projectType → UI kind
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
        return null; // unknown type → ignored
    }
  }
}

class GetAvailableKindsFromActiveUc {
  final IOwnerProjectsRepository repo;
  const GetAvailableKindsFromActiveUc(this.repo);

  Future<Set<String>> call() async {
    final list = await repo.getProjects();
    final kinds = <String>{};

    for (final p in list) {
      final k = _KindMapper.map(p);
      if (k != null) kinds.add(k);
    }

    // ✅ optional fallback if backend returns nothing
    if (kinds.isEmpty) return const {'activities'};
    return kinds;
  }
}
