import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/ai/data/repositories/superadmin_ai_repository_impl.dart';
import 'package:build4all_manager/features/superadmin/ai/data/services/superadmin_ai_api.dart';
import 'package:build4all_manager/features/superadmin/ai/domain/usecases/get_owner_ai_status.dart';
import 'package:build4all_manager/features/superadmin/ai/domain/usecases/toggle_owner_ai.dart';
import 'package:build4all_manager/features/superadmin/ai/presentation/bloc/superadmin_ai_bloc.dart';
import 'package:build4all_manager/features/superadmin/ai/presentation/bloc/superadmin_ai_event.dart';
import 'package:build4all_manager/features/superadmin/ai/presentation/widgets/owner_ai_toggle_tile.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/models/owner_app_in_project_dto.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/services/project_api.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/owner_app_orders_screen.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:build4all_manager/shared/utils/search_match.dart';
import 'package:build4all_manager/shared/widgets/app_search_bar.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class OwnerAppsInProjectScreen extends StatefulWidget {
  final int projectId;
  final String projectName;
  final int adminId;
  final String ownerName;

  const OwnerAppsInProjectScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.adminId,
    required this.ownerName,
  });

  @override
  State<OwnerAppsInProjectScreen> createState() =>
      _OwnerAppsInProjectScreenState();
}

class _OwnerAppsInProjectScreenState extends State<OwnerAppsInProjectScreen> {
  late final Dio _dio;
  late final ProjectApi _api;

  bool _loading = true;
  String? _error;

  List<OwnerAppInProjectDto> _apps = const [];
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
      final res =
          await _api.ownerAppsInProject(widget.projectId, widget.adminId);
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(OwnerAppInProjectDto.fromJson).toList();

      setState(() {
        _apps = items;
        _loading = false;
      });
       } catch (e) {
      final msg = ApiErrorHandler.message(e);
      setState(() {
        _error = msg;
        _loading = false;
      });
      if (mounted) AppToast.error(context, msg);
    }
  }

  List<OwnerAppInProjectDto> get _filtered {
    if (_q.trim().isEmpty) return _apps;
    return _apps
        .where(
          (a) => searchMatch(
            _q,
            [a.appName, a.slug, a.status, a.apkUrl, a.bundleUrl, a.ipaUrl],
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppSearchAppBar(
        hint: t.ownerAppsSearchHint,
        showBack: true,
        onQueryChanged: (q) => setState(() => _q = q),
        onClear: () => setState(() => _q = ''),
      ),
      body: BlocProvider(
        create: (_) {
          final dio = DioClient.ensure();
          final api = SuperAdminAiApi(dio);
          final repo = SuperAdminAiRepositoryImpl(api);
          final getStatus = GetOwnerAiStatus(repo);
          final toggle = ToggleOwnerAi(repo);

          return SuperAdminAiBloc(getStatus: getStatus, toggle: toggle)
            ..add(SuperAdminAiStarted(widget.adminId));
        },
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const _AppsSkeleton()
              : _error != null
                  ? _InlineError(message: _error!, onRetry: _load)
                  : _apps.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SizedBox(height: 24),
                            Center(child: Text(t.ownerAppsEmpty)),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: _filtered.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            // ✅ first item = AI toggle card
                            if (i == 0) {
                              return OwnerAiToggleTile(ownerId: widget.adminId);
                            }

                            final a = _filtered[i - 1];

                            final title = a.appName.isEmpty
                                ? t.ownerAppsUnnamed
                                : a.appName;

                            return Card(
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                title: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  t.ownerAppsSlugStatus(a.slug, a.status),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if ((a.apkUrl ?? '').isNotEmpty)
                                      const Icon(Icons.android_rounded,
                                          size: 18),
                                    if ((a.bundleUrl ?? '').isNotEmpty)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(Icons.archive_rounded,
                                            size: 18),
                                      ),
                                    if ((a.ipaUrl ?? '').isNotEmpty)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(Icons.phone_iphone_rounded,
                                            size: 18),
                                      ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded),
                                  ],
                                ),
                                onTap: () {
                                  final appTitle =
                                      a.appName.isEmpty ? a.slug : a.appName;

                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => OwnerAppOrdersScreen(
                                        ownerProjectId: a.id,
                                        appName: appTitle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
        ),
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

class _AppsSkeleton extends StatelessWidget {
  const _AppsSkeleton();

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
