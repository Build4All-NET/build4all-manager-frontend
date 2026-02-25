import 'package:auto_size_text/auto_size_text.dart';
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
import '../../../common/domain/usecases/get_my_requests_uc.dart';

import '../../domain/usecases/get_available_kinds_from_active_uc.dart';
import '../../data/services/owner_projects_api.dart';
import '../../data/repositories/owner_projects_repository_impl.dart';

import '../bloc/owner_home_bloc.dart';
import '../bloc/owner_home_event.dart';
import '../bloc/owner_home_state.dart';

import '../widgets/request_card.dart';
import '../../data/static_project_models.dart';
import '../widgets/project_template_card.dart';

// ✅ SAME call style as Profile -> /admin/users/me
import 'package:build4all_manager/features/owner/ownerprofile/data/services/owner_profile_api.dart';

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
    final getAvailableKinds = GetAvailableKindsFromActiveUc(projectsRepo);

    return BlocProvider(
      create: (_) => OwnerHomeBloc(
        getMyRequests: GetMyRequestsUc(generalRepo),
        getAppConfig: GetAppConfigUc(generalRepo),
        getAvailableKinds: getAvailableKinds,
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
    // ✅ API FIRST (so edited name shows)
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
      // fallback 1: store
      final store = OwnerMeStore.I.displayName.value;
      if ((store ?? '').trim().isNotEmpty) return store;

      // fallback 2: router passed
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
                      final aspect = cardW < 190 ? 0.86 : (cardW < 230 ? 0.95 : 1.05);

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
    // ✅ Block taps while availability is still loading (first load)
    final isAvailabilityBootstrapping = state.loading &&
        state.availableKinds.isEmpty &&
        state.kindToProjectId.isEmpty;

    if (isAvailabilityBootstrapping) {
      AppToast.info(context, 'Please wait... loading projects');
      return; // ✅ IMPORTANT
    }

    // ✅ If not available, show toast and STOP (do not navigate)
    if (!isAvailable) {
      AppToast.info(context, l10n.owner_proj_comingSoon);
      return; // ✅ THIS was missing
    }

    // ✅ Only navigate when backend already confirmed availability
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

                // ----- Recent requests -----
                SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: AutoSizeText(
                          _safe(l10n.owner_home_recentRequests, 'Recent requests'),
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
                        onPressed: () => context.push(
                          '/owner/requests/list',
                          extra: {'ownerId': widget.ownerId, 'dio': widget.dio},
                        ),
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

                if (state.loading && state.recent.isEmpty)
                  const SliverToBoxAdapter(child: _LoadingList())
                else if (state.recent.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: AutoSizeText(
                        _safe(l10n.owner_home_noRecent, 'No recent requests'),
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
                    itemCount: state.recent.length,
                    itemBuilder: (_, i) => RequestCard(req: state.recent[i]),
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
