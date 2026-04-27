import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/models/project_dto.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/services/project_api.dart';
import 'package:build4all_manager/features/superadmin/dashboard/domain/entities/project_summary.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/OwnersByProjectScreen.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/widgets/pro_project_tile.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:build4all_manager/shared/utils/search_match.dart';
import 'package:build4all_manager/shared/widgets/app_search_bar.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late final Dio _dio;
  late final ProjectApi _api;

  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  List<ProjectSummary> _projects = const [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    _dio = DioClient.ensure();
    _api = ProjectApi(_dio);
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.list();
      final raw = res.data;

      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      final items = list.map((e) => ProjectDto.fromJson(e).toEntity()).toList();

      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (!mounted) return;
      setState(() {
        _projects = items;
        _loading = false;
      });
    } catch (e) {
      final msg = ApiErrorHandler.message(e);

      if (!mounted) return;
      setState(() {
        _error = msg;
        _loading = false;
      });

      AppToast.error(context, msg);
    }
  }

  Future<void> _enableProject(ProjectSummary project) async {
    if (_actionLoading) return;

    setState(() => _actionLoading = true);

    try {
      await _api.enableProject(project.id);
      await _load();

      if (!mounted) return;
      AppToast.success(context, 'Project enabled');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, ApiErrorHandler.message(e));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _disableProject(ProjectSummary project) async {
    if (_actionLoading) return;

    setState(() => _actionLoading = true);

    try {
      await _api.disableProject(project.id);
      await _load();

      if (!mounted) return;
      AppToast.success(context, 'Project disabled');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, ApiErrorHandler.message(e));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _archiveProject(ProjectSummary project) async {
    if (_actionLoading) return;

    final confirmed = await _confirmArchive(project);
    if (confirmed != true) return;

    setState(() => _actionLoading = true);

    try {
      await _api.archiveProject(project.id);
      await _load();

      if (!mounted) return;
      AppToast.success(context, 'Project archived');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, ApiErrorHandler.message(e));
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<bool?> _confirmArchive(ProjectSummary project) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;

        return AlertDialog(
          title: const Text('Archive project?'),
          content: Text(
            'Are you sure you want to archive "${project.name}"?\n\n'
            'This will hide it from owners, but it will not delete existing owner apps.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  List<ProjectSummary> get _filtered {
    if (_q.trim().isEmpty) return _projects;

    return _projects
        .where(
          (p) => searchMatch(
            _q,
            [
              p.name,
              '${p.id}',
              p.description ?? '',
              p.active ? 'active' : 'inactive',
            ],
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppSearchAppBar(
        hint: t.projectsSearchHint,
        showBack: true,
        onQueryChanged: (q) => setState(() => _q = q),
        onClear: () => setState(() => _q = ''),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const _ProjectsSkeleton()
                : _error != null
                    ? _InlineError(message: _error!, onRetry: _load)
                    : _projects.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 24),
                              Center(child: Text(t.projectsEmpty)),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: [
                              Card(
                                elevation: 0,
                                clipBehavior: Clip.antiAlias,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1, thickness: .5),
                                  itemBuilder: (_, i) {
                                    final p = _filtered[i];

                                    return ProProjectTile(
                                      project: p,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                OwnersByProjectScreen(
                                              projectId: p.id,
                                              projectName: p.name,
                                            ),
                                          ),
                                        );
                                      },
                                      onEnable: () => _enableProject(p),
                                      onDisable: () => _disableProject(p),
                                      onArchive: () => _archiveProject(p),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),

          if (_actionLoading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withOpacity(.04),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.error.withOpacity(.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.error.withOpacity(.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.error),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(t.commonRetry),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectsSkeleton extends StatelessWidget {
  const _ProjectsSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 20,
          width: 160,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Column(
            children: List.generate(
              8,
              (i) => Container(
                height: 64,
                margin: EdgeInsets.only(bottom: i == 7 ? 0 : .5),
                color: cs.surfaceContainerHighest,
              ),
            ),
          ),
        ),
      ],
    );
  }
}