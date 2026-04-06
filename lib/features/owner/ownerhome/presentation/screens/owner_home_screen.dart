import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/features/owner/common/domain/usecases/get_my_apps_uc.dart';
import 'package:build4all_manager/features/owner/ownerhome/data/repositories/owner_projects_repository_impl.dart';
import 'package:build4all_manager/features/owner/ownerhome/data/services/owner_projects_api.dart';
import 'package:build4all_manager/features/owner/ownerhome/domain/usecases/get_platform_projects_uc.dart';
import 'package:build4all_manager/shared/state/owner_me_store.dart';
import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../common/data/repositories/owner_repository_impl.dart';
import '../../../common/data/services/owner_api.dart';
import '../../../common/domain/usecases/get_app_config_uc.dart';

import '../bloc/owner_home_bloc.dart';
import '../bloc/owner_home_event.dart';
import '../bloc/owner_home_state.dart';

import '../../data/static_project_models.dart';
import '../widgets/project_template_card.dart';

import 'package:build4all_manager/features/owner/ownerprofile/data/services/owner_profile_api.dart';
import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';

class OwnerHomeScreen extends StatelessWidget {
  final int ownerId;
  final Dio dio;
  final String? ownerName;

  const OwnerHomeScreen({
    super.key,
    required this.ownerId,
    required this.dio,
    this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final generalRepo = OwnerRepositoryImpl(OwnerApi(dio));
    final projectsRepo = OwnerProjectsRepositoryImpl(OwnerProjectsApi(dio));

    return BlocProvider(
      create: (_) => OwnerHomeBloc(
        getAppConfig: GetAppConfigUc(generalRepo),
        getMyApps: GetMyAppsUc(generalRepo),
        getPlatformProjects: GetPlatformProjectsUc(projectsRepo),
      )..add(OwnerHomeStarted(ownerId)),
      child: _HomeScaffold(
        ownerId: ownerId,
        dio: dio,
        ownerName: ownerName,
      ),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  final int ownerId;
  final Dio dio;
  final String? ownerName;

  const _HomeScaffold({
    required this.ownerId,
    required this.dio,
    this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _HomeBody(
          ownerId: ownerId,
          dio: dio,
          ownerName: ownerName,
        ),
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  final int ownerId;
  final Dio dio;
  final String? ownerName;

  const _HomeBody({
    required this.ownerId,
    required this.dio,
    this.ownerName,
  });

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    final current = OwnerMeStore.I.displayName.value;
    if ((current ?? '').trim().isEmpty) {
      final passed = widget.ownerName?.trim();
      if (passed != null && passed.isNotEmpty) {
        OwnerMeStore.I.setName(passed);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fresh = await _loadDisplayName();
      if (!mounted) return;
      if ((fresh ?? '').trim().isNotEmpty) {
        OwnerMeStore.I.setName(fresh);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _loadDisplayName() async {
    try {
      final api = OwnerProfileApi(widget.dio);
      final dto = await api.getMe();

      final first = dto.firstName.trim();
      final last = dto.lastName.trim();
      final fullName = [first, last].where((e) => e.isNotEmpty).join(' ').trim();

      if (fullName.isNotEmpty) return fullName;

      final u = dto.username.trim();
      return u.isNotEmpty ? u : null;
    } catch (_) {
      final store = OwnerMeStore.I.displayName.value;
      if ((store ?? '').trim().isNotEmpty) return store;

      final passed = widget.ownerName?.trim();
      return (passed != null && passed.isNotEmpty) ? passed : null;
    }
  }

  bool _isEmail(String s) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

  String _firstPartSafe(String? raw) {
    if (raw == null) return '';
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (_isEmail(s)) return '';
    if (s.startsWith('@')) return s.substring(1).trim();
    return s.split(RegExp(r'\s+')).first.trim();
  }

  String? _errText(OwnerHomeState s) {
    try {
      final dynamic d = s;
      final e = d.error ?? d.errorMessage ?? d.message;
      if (e == null) return null;
      final t = e.toString();
      return t.trim().isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  String _serverRootNoApi(Dio d) {
    final base = d.options.baseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  String _norm(String? value) => (value ?? '').trim().toLowerCase();

  bool _matchesProject(OwnerProject app, String query) {
    final q = _norm(query);
    if (q.isEmpty) return true;

    final appName = _norm(app.appName);
    final projectName = _norm(app.projectName);
    final status = _norm(app.status);
    final linkId = app.linkId.toString().toLowerCase();

    return appName.contains(q) ||
        projectName.contains(q) ||
        status.contains(q) ||
        linkId.contains(q);
  }

  List<OwnerProject> _filteredProjects(List<OwnerProject> apps) {
    final q = _searchQuery.trim();
    if (q.isEmpty) return apps;
    return apps.where((app) => _matchesProject(app, q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ux = Theme.of(context).extension<UiTokens>()!;

    final w = MediaQuery.of(context).size.width;
    final pagePad = w >= 480
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
        : ux.pagePad;

    final hello = l10n.owner_home_hello;
    final subtitle = l10n.owner_home_subtitle;

    return Padding(
      padding: pagePad,
      child: BlocConsumer<OwnerHomeBloc, OwnerHomeState>(
        listenWhen: (prev, curr) {
          final prevErr = _errText(prev);
          final currErr = _errText(curr);
          return prevErr != currErr && (currErr?.isNotEmpty ?? false);
        },
        listener: (context, state) {
          final msg = _errText(state);
          if (msg != null && msg.trim().isNotEmpty) {
            AppToast.error(context, msg);
          }
        },
        builder: (context, state) {
          final filteredApps = _filteredProjects(state.myApps);
          final hasSearch = _searchQuery.trim().isNotEmpty;
          final visibleApps = hasSearch
              ? filteredApps
              : filteredApps.take(math.min(5, filteredApps.length)).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<OwnerHomeBloc>().add(
                    OwnerHomeRefreshed(widget.ownerId),
                  );

              final fresh = await _loadDisplayName();
              if (!mounted) return;
              if ((fresh ?? '').trim().isNotEmpty) {
                OwnerMeStore.I.setName(fresh);
              }
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: OwnerMeStore.I.displayName,
                    builder: (context, storedName, _) {
                      final display = _firstPartSafe(storedName);
                      final greeting = display.isEmpty ? hello : '$hello $display';

                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  greeting,
                                  maxLines: 1,
                                  minFontSize: 16,
                                  stepGranularity: 0.5,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                AutoSizeText(
                                  subtitle,
                                  maxLines: 2,
                                  minFontSize: 12,
                                  stepGranularity: 0.5,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _OwnerProjectsSearchField(
                    controller: _searchCtrl,
                    hintText: l10n.owner_home_search_hint,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: AutoSizeText(
                    l10n.owner_home_chooseProject,
                    maxLines: 1,
                    minFontSize: 14,
                    stepGranularity: 0.5,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverPadding(
                  padding: EdgeInsets.only(bottom: ux.radiusMd),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final cross = constraints.crossAxisExtent;
                      final cols = cross >= 900 ? 4 : (cross >= 600 ? 3 : 2);
                      const spacing = 12.0;

                      final cardW = (cross - (spacing * (cols - 1))) / cols;
                      final aspect =
                          cardW < 190 ? 0.86 : (cardW < 230 ? 0.95 : 1.05);

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: aspect,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final tpl = projectTemplates[i];
                            final kind = tpl.kind.toLowerCase();

                            final isAvailable =
                                state.availableKinds.contains(kind);
                            final int? realProjectId =
                                state.kindToProjectId[kind];

                            return ProjectTemplateCard(
                              tpl: tpl,
                              isAvailable: !(state.loading &&
                                      state.availableKinds.isEmpty &&
                                      state.kindToProjectId.isEmpty) &&
                                  isAvailable,
                              onOpen: () {
                                final isBoot = state.loading &&
                                    state.availableKinds.isEmpty &&
                                    state.kindToProjectId.isEmpty;

                                if (isBoot) {
                                  AppToast.info(
                                    context,
                                    l10n.owner_home_loading_projects,
                                  );
                                  return;
                                }

                                if (!isAvailable) {
                                  AppToast.info(
                                    context,
                                    l10n.owner_proj_comingSoon,
                                  );
                                  return;
                                }

                                context.push(
                                  '/owner/project/${tpl.id}',
                                  extra: {
                                    'canRequest': isAvailable,
                                    'projectId': realProjectId,
                                  },
                                );
                              },
                            );
                          },
                          childCount: projectTemplates.length,
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          l10n.owner_projects_title,
                          maxLines: 1,
                          minFontSize: 14,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/owner/projects'),
                        child: AutoSizeText(
                          l10n.owner_home_viewAll,
                          maxLines: 1,
                          minFontSize: 12,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                if (state.loading && state.myApps.isEmpty)
                  const SliverToBoxAdapter(child: _LoadingList())
                else if (visibleApps.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        hasSearch
                            ? l10n.owner_home_no_matching_projects
                            : l10n.owner_home_no_apps_yet,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: visibleApps.length,
                    itemBuilder: (_, i) {
                      final app = visibleApps[i];
                      return _MyAppSummaryCard(
                        app: app,
                        serverRootNoApi: _serverRootNoApi(widget.dio),
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OwnerProjectsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _OwnerProjectsSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.7)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: tt.bodyLarge?.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: tt.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(.8),
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (controller.text.trim().isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: Icon(
                Icons.close_rounded,
                color: cs.onSurfaceVariant,
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(3, (i) {
        return Container(
          height: 64,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(.45),
            borderRadius: BorderRadius.circular(14),
          ),
        );
      }),
    );
  }
}

class _MyAppSummaryCard extends StatelessWidget {
  final OwnerProject app;
  final String serverRootNoApi;

  const _MyAppSummaryCard({
    required this.app,
    required this.serverRootNoApi,
  });

  String _clean(String? s) => (s ?? '').trim();

  String _statusLabel(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    final s = raw.toUpperCase();

    if (s == 'ACTIVE') return l10n.common_status_active;
    if (s.contains('TEST')) return l10n.common_status_test;
    if (s.contains('LOCAL')) return l10n.common_status_local;
    if (s.contains('PROD')) return l10n.common_status_production;

    return raw;
  }

  (Color bg, Color fg) _statusColors(ColorScheme cs, String raw) {
    final s = raw.toUpperCase();
    if (s == 'ACTIVE') return (cs.primary.withOpacity(.12), cs.primary);
    if (s.contains('TEST')) {
      return (cs.tertiaryContainer.withOpacity(.30), cs.tertiary);
    }
    if (s.contains('LOCAL')) {
      return (cs.secondary.withOpacity(.14), cs.secondary);
    }
    return (cs.outlineVariant.withOpacity(.22), cs.onSurface);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final name = _clean(app.appName).isNotEmpty
        ? _clean(app.appName)
        : _clean(app.projectName);

    final status = _clean(app.status).isNotEmpty ? _clean(app.status) : '—';
    final (bg, fg) = _statusColors(cs, status);

    final logoUrl = _clean(app.logoUrl);
    final fullLogo = logoUrl.isEmpty
        ? null
        : (logoUrl.startsWith('http') ? logoUrl : '$serverRootNoApi$logoUrl');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.65)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: fullLogo == null
                ? Icon(
                    Icons.apps_rounded,
                    color: cs.onSurface.withOpacity(.65),
                  )
                : Image.network(
                    fullLogo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.apps_rounded,
                      color: cs.onSurface.withOpacity(.65),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? '—' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(context, status),
                        style: tt.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.common_project_label}: '
                  '${_clean(app.projectName).isEmpty ? '—' : _clean(app.projectName)}'
                  '  •  '
                  '${l10n.common_link_id_label}: ${app.linkId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: l10n.common_open,
            onPressed: () {
              context.push('/owner/projects');
            },
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: cs.onSurface.withOpacity(.7),
            ),
          ),
        ],
      ),
    );
  }
}