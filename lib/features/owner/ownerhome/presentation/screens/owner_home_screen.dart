import 'dart:async';
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
  bool _showBootSkeleton = true;
  Timer? _bootTimer;

  @override
  void initState() {
    super.initState();

    _bootTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        _showBootSkeleton = false;
      });
    });

    final current = OwnerMeStore.I.displayName.value;

    if ((current ?? '').trim().isNotEmpty &&
        _looksLikeUsernameOrEmail(current!)) {
      OwnerMeStore.I.clear();
    }

    final passedFirstName = _firstNameOnly(widget.ownerName);

    if (passedFirstName.isNotEmpty &&
        !_looksLikeUsernameOrEmail(widget.ownerName ?? '')) {
      OwnerMeStore.I.setName(passedFirstName);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fresh = await _loadDisplayName();

      if (!mounted) return;

      if ((fresh ?? '').trim().isNotEmpty) {
        OwnerMeStore.I.setName(fresh);
      } else {
        OwnerMeStore.I.clear();
      }
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _loadDisplayName() async {
    try {
      final api = OwnerProfileApi(widget.dio);
      final dto = await api.getMe();

      final firstName = dto.firstName.trim();

      if (firstName.isNotEmpty && !_looksLikeUsernameOrEmail(firstName)) {
        return firstName;
      }

      final fullName = [dto.firstName.trim(), dto.lastName.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim();

      final firstFromFull = _firstNameOnly(fullName);

      if (firstFromFull.isNotEmpty &&
          !_looksLikeUsernameOrEmail(firstFromFull)) {
        return firstFromFull;
      }

      return null;
    } catch (_) {
      final stored = OwnerMeStore.I.displayName.value;
      final safeStored = _firstNameOnly(stored);

      if (safeStored.isNotEmpty && !_looksLikeUsernameOrEmail(stored ?? '')) {
        return safeStored;
      }

      final passed = _firstNameOnly(widget.ownerName);

      if (passed.isNotEmpty &&
          !_looksLikeUsernameOrEmail(widget.ownerName ?? '')) {
        return passed;
      }

      return null;
    }
  }

  bool _isEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  bool _looksLikeUsernameOrEmail(String value) {
    final s = value.trim();

    if (s.isEmpty) return true;
    if (_isEmail(s)) return true;
    if (s.startsWith('@')) return true;

    if (s.contains('_')) return true;
    if (s.contains('.')) return true;
    if (s.contains('-')) return true;
    if (RegExp(r'\d').hasMatch(s)) return true;

    final lower = s.toLowerCase();

    if (lower.contains('owner')) return true;
    if (lower.contains('admin')) return true;
    if (lower.contains('user')) return true;
    if (lower.contains('manager')) return true;
    if (lower.contains('build4all')) return true;

    return false;
  }

  String _firstNameOnly(String? raw) {
    final value = (raw ?? '').trim();

    if (value.isEmpty) return '';
    if (_looksLikeUsernameOrEmail(value)) return '';

    return value.split(RegExp(r'\s+')).first.trim();
  }

  String? _errText(OwnerHomeState state) {
    try {
      final dynamic dynamicState = state;
      final error = dynamicState.error ??
          dynamicState.errorMessage ??
          dynamicState.message;

      if (error == null) return null;

      final text = error.toString();
      return text.trim().isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  String _serverRootNoApi(Dio dio) {
    final base = dio.options.baseUrl;
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  String _norm(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

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

  Future<void> _refresh(BuildContext context) async {
    context.read<OwnerHomeBloc>().add(
          OwnerHomeRefreshed(widget.ownerId),
        );

    final fresh = await _loadDisplayName();

    if (!mounted) return;

    if ((fresh ?? '').trim().isNotEmpty) {
      OwnerMeStore.I.setName(fresh);
    } else {
      OwnerMeStore.I.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ux = Theme.of(context).extension<UiTokens>()!;

    final width = MediaQuery.of(context).size.width;

    final pagePad = width >= 480
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 16)
        : ux.pagePad;

    final hello = l10n.owner_home_hello.trim();
    final subtitle = l10n.owner_home_subtitle;

    return Padding(
      padding: pagePad,
      child: BlocConsumer<OwnerHomeBloc, OwnerHomeState>(
        listenWhen: (previous, current) {
          final previousError = _errText(previous);
          final currentError = _errText(current);

          return previousError != currentError &&
              (currentError?.isNotEmpty ?? false);
        },
        listener: (context, state) {
          final message = _errText(state);

          if (message != null && message.trim().isNotEmpty) {
            AppToast.error(context, message);
          }
        },
        builder: (context, state) {
          final filteredApps = _filteredProjects(state.myApps);
          final hasSearch = _searchQuery.trim().isNotEmpty;
          final visibleApps = hasSearch
              ? filteredApps
              : filteredApps.take(math.min(5, filteredApps.length)).toList();

          final showNiceLoading = _showBootSkeleton ||
              (state.loading &&
                  state.platformProjects.isEmpty &&
                  state.myApps.isEmpty);

          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: showNiceLoading
                  ? const _OwnerHomeSkeletonView(
                      key: ValueKey('owner-home-skeleton'),
                    )
                  : CustomScrollView(
                      key: const ValueKey('owner-home-content'),
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: ValueListenableBuilder<String?>(
                            valueListenable: OwnerMeStore.I.displayName,
                            builder: (context, storedName, _) {
                              final rawStored = storedName?.trim() ?? '';

                              final display = rawStored.isEmpty ||
                                      _looksLikeUsernameOrEmail(rawStored)
                                  ? ''
                                  : _firstNameOnly(rawStored);

                              final greeting =
                                  display.isEmpty ? hello : '$hello $display';

                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AutoSizeText(
                                          greeting,
                                          maxLines: 1,
                                          minFontSize: 16,
                                          stepGranularity: 0.5,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              tt.headlineSmall?.copyWith(
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

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),

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

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 16),
                        ),

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

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),

                        SliverPadding(
                          padding: EdgeInsets.only(bottom: ux.radiusMd),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final cross = constraints.crossAxisExtent;

                              final cols = cross >= 900
                                  ? 4
                                  : cross >= 600
                                      ? 3
                                      : 2;

                              const spacing = 12.0;

                              final cardWidth =
                                  (cross - (spacing * (cols - 1))) / cols;

                              final aspect = cardWidth < 190
                                  ? 0.86
                                  : cardWidth < 230
                                      ? 0.95
                                      : 1.05;

                              final sorted = [...state.platformProjects]
                                ..sort(
                                  (a, b) => a.displayOrder
                                      .compareTo(b.displayOrder),
                                );

                              final showPlatformSkeleton = state.loading &&
                                  state.platformProjects.isEmpty;

                              if (showPlatformSkeleton) {
                                return SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    mainAxisSpacing: spacing,
                                    crossAxisSpacing: spacing,
                                    childAspectRatio: aspect,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (_, __) => const _SkeletonCard(),
                                    childCount: cols * 2,
                                  ),
                                );
                              }

                              return SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  mainAxisSpacing: spacing,
                                  crossAxisSpacing: spacing,
                                  childAspectRatio: aspect,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final project = sorted[index];
                                    final isAvailable = project.active;

                                    return ProjectTemplateCard(
                                      project: project,
                                      isAvailable: isAvailable,
                                      onOpen: () {
                                        if (state.loading && sorted.isEmpty) {
                                          AppToast.info(
                                            context,
                                            l10n.owner_home_loading_projects,
                                          );
                                          return;
                                        }

                                        context.push(
                                          '/owner/project/${project.id}',
                                          extra: {
                                            'canRequest': isAvailable,
                                            'projectId': project.id,
                                            'projectType':
                                                project.projectType ?? '',
                                          },
                                        );
                                      },
                                    );
                                  },
                                  childCount: sorted.length,
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

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 10),
                        ),

                        if (state.loading && state.myApps.isEmpty)
                          const SliverToBoxAdapter(
                            child: _LoadingList(),
                          )
                        else if (!state.loading && visibleApps.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 6,
                                bottom: 12,
                              ),
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
                            itemBuilder: (_, index) {
                              final app = visibleApps[index];

                              return _MyAppSummaryCard(
                                app: app,
                                serverRootNoApi:
                                    _serverRootNoApi(widget.dio),
                              );
                            },
                          ),

                        const SliverToBoxAdapter(
                          child: SizedBox(height: 12),
                        ),
                      ],
                    ),
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
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.7),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurface,
              ),
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

class _OwnerHomeSkeletonView extends StatelessWidget {
  const _OwnerHomeSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget bar({
      required double width,
      required double height,
      double radius = 999,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(.65),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return CustomScrollView(
      key: const ValueKey('owner-home-skeleton-scroll'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(width: 150, height: 24),
              const SizedBox(height: 8),
              bar(width: 260, height: 13),
              const SizedBox(height: 16),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(.7),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      color: cs.onSurfaceVariant.withOpacity(.5),
                    ),
                    const SizedBox(width: 10),
                    bar(width: 180, height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              bar(width: 150, height: 18),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final cross = constraints.crossAxisExtent;

            final cols = cross >= 900
                ? 4
                : cross >= 600
                    ? 3
                    : 2;

            const spacing = 12.0;

            final cardWidth = (cross - (spacing * (cols - 1))) / cols;

            final aspect = cardWidth < 190
                ? 0.86
                : cardWidth < 230
                    ? 0.95
                    : 1.05;

            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: aspect,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, __) => const _SkeletonCard(),
                childCount: cols * 2,
              ),
            );
          },
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 18),
        ),
        SliverToBoxAdapter(
          child: Row(
            children: [
              bar(width: 120, height: 18),
              const Spacer(),
              bar(width: 70, height: 14),
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 10),
        ),
        const SliverToBoxAdapter(
          child: _LoadingList(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 18),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.40),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(.75),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(.75),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 90,
              height: 10,
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(.75),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (_) {
        return const _MyAppSkeletonCard();
      }),
    );
  }
}

class _MyAppSkeletonCard extends StatelessWidget {
  const _MyAppSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget bar({
      required double width,
      required double height,
      double radius = 999,
    }) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(.65),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.65),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(.65),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(width: 140, height: 13),
                const SizedBox(height: 8),
                bar(width: 220, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 10),
          bar(width: 26, height: 26, radius: 10),
        ],
      ),
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

  String _clean(String? value) {
    return (value ?? '').trim();
  }

  String _statusLabel(BuildContext context, String raw) {
    final l10n = AppLocalizations.of(context)!;
    final status = raw.toUpperCase();

    if (status == 'ACTIVE') return l10n.common_status_active;
    if (status.contains('TEST')) return l10n.common_status_test;
    if (status.contains('LOCAL')) return l10n.common_status_local;
    if (status.contains('PROD')) return l10n.common_status_production;

    return raw;
  }

  (Color bg, Color fg) _statusColors(ColorScheme cs, String raw) {
    final status = raw.toUpperCase();

    if (status == 'ACTIVE') {
      return (
        cs.primary.withOpacity(.12),
        cs.primary,
      );
    }

    if (status.contains('TEST')) {
      return (
        cs.tertiaryContainer.withOpacity(.30),
        cs.tertiary,
      );
    }

    if (status.contains('LOCAL')) {
      return (
        cs.secondary.withOpacity(.14),
        cs.secondary,
      );
    }

    return (
      cs.outlineVariant.withOpacity(.22),
      cs.onSurface,
    );
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
        : logoUrl.startsWith('http')
            ? logoUrl
            : '$serverRootNoApi$logoUrl';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.65),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(.5),
              ),
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