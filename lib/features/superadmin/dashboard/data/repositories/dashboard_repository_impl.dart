import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/project_summary.dart';
import '../../domain/repositories/i_dashboard_repository.dart';
import '../models/project_dto.dart';
import '../services/project_api.dart';
import '../services/licensing_api.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final ProjectApi projects;
  final LicensingApi licensing;

  DashboardRepositoryImpl(this.projects, this.licensing);

  @override
  Future<(DashboardOverview, List<ProjectSummary>)> load() async {
    // projects
    final res = await projects.list();
    final list = (res.data as List).cast<Map<String, dynamic>>();
    final items = list.map((e) => ProjectDto.fromJson(e).toEntity()).toList();

    final total = items.length;
    final active = items.where((e) => e.active).length;
    final inactive = total - active;

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recent = items.take(8).toList();

    // ✅ pending upgrade requests count (super admin)
    int pendingCount = 0;
    try {
      final r2 = await licensing.pendingUpgradeRequests();
      final pending = (r2.data as List);
      pendingCount = pending.length;
    } catch (_) {
      // ignore count failure (dashboard should still load)
      pendingCount = 0;
    }

    return (
      DashboardOverview(
        totalProjects: total,
        activeProjects: active,
        inactiveProjects: inactive,
        pendingUpgradeRequests: pendingCount,
      ),
      recent
    );
  }
}
