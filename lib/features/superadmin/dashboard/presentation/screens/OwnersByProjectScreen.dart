import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/models/ProjectOwnerSummaryDto.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/services/project_api.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/owner_apps_in_project_screen.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/search_match.dart';
import 'package:build4all_manager/shared/widgets/app_search_bar.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OwnersByProjectScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const OwnersByProjectScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<OwnersByProjectScreen> createState() => _OwnersByProjectScreenState();
}

class _OwnersByProjectScreenState extends State<OwnersByProjectScreen> {
  late final Dio _dio;
  late final ProjectApi _api;

  bool _loading = true;
  String? _error;
  List<ProjectOwnerSummaryDto> _owners = const [];
  String _q = '';

  @override
  void initState() {
    super.initState();
    _dio = DioClient.ensure();
    _api = ProjectApi(_dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.ownersByProject(widget.projectId);
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(ProjectOwnerSummaryDto.fromJson).toList();

      setState(() {
        _owners = items;
        _loading = false;
      });
    } catch (e) {
      final msg = e.toString();
      setState(() {
        _error = msg;
        _loading = false;
      });
      if (mounted) AppToast.error(context, msg);
    }
  }

  List<ProjectOwnerSummaryDto> get _filtered {
    if (_q.trim().isEmpty) return _owners;
    return _owners
        .where((o) => searchMatch(_q, [o.fullName, o.email, '${o.appsCount}']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppSearchAppBar(
        hint: l10n.search_owners_hint,
        showBack: true,
        onQueryChanged: (q) => setState(() => _q = q),
        onClear: () => setState(() => _q = ''),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const _OwnersSkeleton()
            : _error != null
                ? _InlineError(message: _error!, onRetry: _load)
                : _owners.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const SizedBox(height: 20),
                          Center(child: Text(l10n.empty_owners)),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final o = _filtered[i];
                          return Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_rounded),
                              ),
                              title: Text(o.fullName),
                              subtitle: Text(
                                [
                                  o.email,
                                  if ((o.phoneNumber ?? '').trim().isNotEmpty)
                                    o.phoneNumber!,
                                ].join(' • '),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CountPill(
                                    count: o.appsCount,
                                    label: l10n.apps_count(o.appsCount),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OwnerAppsInProjectScreen(
                                      projectId: widget.projectId,
                                      projectName: widget.projectName,
                                      adminId: o.adminId,
                                      ownerName: o.fullName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  final String label;
  const _CountPill({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.10),
        border: Border.all(color: cs.primary.withOpacity(.20)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
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
              TextButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnersSkeleton extends StatelessWidget {
  const _OwnersSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        8,
        (i) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
