import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/features/owner/common/domain/usecases/get_my_apps_uc.dart';
import 'package:build4all_manager/shared/state/owner_me_store.dart';
import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:build4all_manager/shared/widgets/search_input.dart';
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

// ✅ SAME call style as Profile -> /admin/users/me
import 'package:build4all_manager/features/owner/ownerprofile/data/services/owner_profile_api.dart';

// ✅ entity used in My Apps list
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

    return BlocProvider(
      create: (_) => OwnerHomeBloc(
        getAppConfig: GetAppConfigUc(generalRepo),
        getMyApps: GetMyAppsUc(generalRepo),
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
  @override
  void initState() {
    super.initState();

    // ✅ only use router name if store is empty (avoid forcing old value forever)
    final current = OwnerMeStore.I.displayName.value;
    if ((current ?? '').trim().isEmpty) {
      final passed = widget.ownerName?.trim();
      if (passed != null && passed.isNotEmpty) {
        OwnerMeStore.I.setName(passed);
      }
    }

    // ✅ always sync from API after first frame (real source of truth)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fresh = await _loadDisplayName();
      if (!mounted) return;
      if ((fresh ?? '').trim().isNotEmpty) {
        OwnerMeStore.I.setName(fresh);
      }
    });
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

  String _safe(String? s, String fallback) {
    final t = (s ?? '').trim();
    return t.isEmpty ? fallback : t;
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

  // ✅ quick: extract server root without /api
  String _serverRootNoApi(Dio d) {
    final base = d.options.baseUrl; // e.g. http://host:8080/api
    return base.replaceFirst(RegExp(r'/api/?$'), '');
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

    final hello = _safe(l10n.owner_home_hello, 'Hello');
    final subtitle = _safe(l10n.owner_home_subtitle, 'Welcome back 👋');

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
          return RefreshIndicator(
            onRefresh: () async {
              context.read<OwnerHomeBloc>().add(OwnerHomeRefreshed(widget.ownerId));

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
                // ----- Header -----
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

                // ----- Search -----
                const SliverToBoxAdapter(
                  child: AppSearchInput(
                    hintKey: 'owner_home_search_hint',
                    showFilter: false,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ----- Choose your project -----
                SliverToBoxAdapter(
                  child: AutoSizeText(
                    _safe(l10n.owner_home_chooseProject, 'Choose your project'),
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

                // ----- Projects grid -----
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

                            final isAvailable = state.availableKinds.contains(kind);
                            final int? realProjectId = state.kindToProjectId[kind];

                            return ProjectTemplateCard(
                              tpl: tpl,
                              // ✅ during first load, keep cards visually disabled
                              isAvailable: !(state.loading &&
                                      state.availableKinds.isEmpty &&
                                      state.kindToProjectId.isEmpty) &&
                                  isAvailable,
                              onOpen: () {
                                final isBoot = state.loading &&
                                    state.availableKinds.isEmpty &&
                                    state.kindToProjectId.isEmpty;

                                if (isBoot) {
                                  AppToast.info(context, 'Please wait... loading projects');
                                  return;
                                }

                                if (!isAvailable) {
                                  AppToast.info(context, l10n.owner_proj_comingSoon);
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

                // ✅ MY APPS SUMMARY (replaces Recent Requests)
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          _safe(l10n.owner_projects_title, 'My apps'),
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
                          _safe(l10n.owner_home_viewAll, 'View all'),
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
                else if (state.myApps.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: AutoSizeText(
                        'No apps yet',
                        maxLines: 2,
                        minFontSize: 12,
                        stepGranularity: 0.5,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: state.myApps.length > 5 ? 5 : state.myApps.length,
                    itemBuilder: (_, i) {
                      final app = state.myApps[i];
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

/// ✅ Compact summary card (NOT ProjectTile)
class _MyAppSummaryCard extends StatelessWidget {
  final OwnerProject app;
  final String serverRootNoApi;

  const _MyAppSummaryCard({
    required this.app,
    required this.serverRootNoApi,
  });

  String _clean(String? s) => (s ?? '').trim();

  String _statusLabel(String raw) {
    final s = raw.toUpperCase();
    if (s == 'ACTIVE') return 'Active';
    if (s.contains('TEST')) return 'Test';
    if (s.contains('LOCAL')) return 'Local';
    if (s.contains('PROD')) return 'Production';
    return raw;
  }

  (Color bg, Color fg) _statusColors(ColorScheme cs, String raw) {
    final s = raw.toUpperCase();
    if (s == 'ACTIVE') return (cs.primary.withOpacity(.12), cs.primary);
    if (s.contains('TEST')) return (cs.tertiaryContainer.withOpacity(.30), cs.tertiary);
    if (s.contains('LOCAL')) return (cs.secondary.withOpacity(.14), cs.secondary);
    return (cs.outlineVariant.withOpacity(.22), cs.onSurface);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final name = _clean(app.appName).isNotEmpty ? _clean(app.appName) : _clean(app.projectName);
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
          // Logo
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
                ? Icon(Icons.apps_rounded, color: cs.onSurface.withOpacity(.65))
                : Image.network(
                    fullLogo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.apps_rounded, color: cs.onSurface.withOpacity(.65)),
                  ),
          ),
          const SizedBox(width: 12),

          // Main
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title + status chip
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name.isEmpty ? '—' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: tt.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // meta line
                Text(
                  'Project: ${_clean(app.projectName).isEmpty ? '—' : _clean(app.projectName)}  •  LinkId: ${app.linkId}',
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

          // open button
          IconButton(
            tooltip: 'Open',
            onPressed: () {
              // take user to My Apps screen to manage this app (rebuild/delete/etc)
              context.push('/owner/projects');
            },
            icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: cs.onSurface.withOpacity(.7)),
          ),
        ],
      ),
    );
  }
}