import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/features/owner/common/data/repositories/owner_repository_impl.dart';
import 'package:build4all_manager/features/owner/common/data/services/owner_api.dart';
import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';
import 'package:build4all_manager/features/owner/common/domain/usecases/get_my_apps_uc.dart';
import 'package:build4all_manager/features/owner/ownernav/presentation/controllers/owner_nav_cubit.dart';
import 'package:build4all_manager/features/owner/ownerprojects/presentation/widgets/project_tile.dart';
import 'package:build4all_manager/features/owner/publish/data/services/owner_publish_api.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/owner_projects_bloc.dart';
import '../bloc/owner_projects_event.dart';
import '../bloc/owner_projects_state.dart';

enum _PlatformReadyFilter { all, android, ios }
enum _EnvironmentFilter { all, local, test, production }

class OwnerProjectsScreen extends StatefulWidget {
  final int ownerId;
  final Dio dio;

  const OwnerProjectsScreen({
    super.key,
    required this.ownerId,
    required this.dio,
  });

  @override
  State<OwnerProjectsScreen> createState() => _OwnerProjectsScreenState();
}

class _OwnerProjectsScreenState extends State<OwnerProjectsScreen> {
  static const int _pageSize = 12;
  int _visibleCount = _pageSize;

  _PlatformReadyFilter _platform = _PlatformReadyFilter.all;
  _EnvironmentFilter _env = _EnvironmentFilter.all;

  bool _showFilters = false;

  // ✅ overrides so status updates instantly per-tile (no refresh)
  final Map<int, String> _androidBuildOverride = {};
  final Map<int, String> _iosBuildOverride = {};
  final Map<int, String> _androidErrOverride = {};
  final Map<int, String> _iosErrOverride = {};

  // ✅ IMPORTANT: create repo + bloc ONCE (NOT inside build)
  late final OwnerRepositoryImpl _repo;
  late final OwnerProjectsBloc _bloc;
  late final OwnerPublishApi _publishApi;

  bool _cleanupScheduled = false;

  @override
  void initState() {
    super.initState();
    _repo = OwnerRepositoryImpl(OwnerApi(widget.dio));
    _publishApi = OwnerPublishApi(widget.dio);

    _bloc = OwnerProjectsBloc(getMyApps: GetMyAppsUc(_repo))
      ..add(OwnerProjectsStarted(widget.ownerId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  // ---------------- Helpers ----------------

  String _serverRootNoApi(Dio d) {
    final base = d.options.baseUrl; // e.g. http://host:8080/api
    return base.replaceFirst(RegExp(r'/api/?$'), '');
  }

  Future<void> _refresh() async {
    _bloc.add(OwnerProjectsStarted(widget.ownerId));
    if (mounted) setState(() => _visibleCount = _pageSize);
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _rebuildAndroid(BuildContext ctx, OwnerProject p) async {
    final id = p.linkId;
    final l10n = AppLocalizations.of(ctx)!;

    if (mounted) {
      setState(() {
        _androidBuildOverride[id] = 'QUEUED';
        _androidErrOverride.remove(id);
      });
    }

    try {
      await _repo.rebuildAndroid(linkId: id);

      if (ctx.mounted) AppToast.success(ctx, l10n.owner_projects_rebuild_queued);
      _bloc.add(OwnerProjectsRefreshed(widget.ownerId));
    } catch (e) {
      if (mounted) {
        setState(() {
          _androidBuildOverride.remove(id);
          _androidErrOverride.remove(id);
        });
      }
      if (ctx.mounted) {
        AppToast.error(ctx, l10n.owner_projects_rebuild_failed(e.toString()));
      }
    }
  }

  Future<void> _rebuildIos(BuildContext ctx, OwnerProject p) async {
    final id = p.linkId;
    final l10n = AppLocalizations.of(ctx)!;

    if (mounted) {
      setState(() {
        _iosBuildOverride[id] = 'QUEUED';
        _iosErrOverride.remove(id);
      });
    }

    try {
      await _repo.rebuildIos(linkId: id);

      if (ctx.mounted) AppToast.success(ctx, l10n.owner_projects_rebuild_queued);
      _bloc.add(OwnerProjectsRefreshed(widget.ownerId));
    } catch (e) {
      if (mounted) {
        setState(() {
          _iosBuildOverride.remove(id);
          _iosErrOverride.remove(id);
        });
      }
      if (ctx.mounted) {
        AppToast.error(ctx, l10n.owner_projects_rebuild_failed(e.toString()));
      }
    }
  }

  bool _androidReady(OwnerProject p) {
    final apk = (p.apkUrl ?? '').trim();
    final aab = (p.bundleUrl ?? '').trim();
    return apk.isNotEmpty || aab.isNotEmpty;
  }

  bool _iosReady(OwnerProject p) {
    final ipa = (p.ipaUrl ?? '').trim();
    return ipa.isNotEmpty;
  }

  bool _matchPlatform(OwnerProject p) {
    switch (_platform) {
      case _PlatformReadyFilter.all:
        return true;
      case _PlatformReadyFilter.android:
        return _androidReady(p);
      case _PlatformReadyFilter.ios:
        return _iosReady(p);
    }
  }

  bool _matchEnv(OwnerProject p) {
    if (_env == _EnvironmentFilter.all) return true;

    final s = p.status.toLowerCase();
    if (_env == _EnvironmentFilter.local) return s.contains('local');
    if (_env == _EnvironmentFilter.test) return s.contains('test');
    if (_env == _EnvironmentFilter.production) {
      return s.contains('prod') || s.contains('production');
    }
    return true;
  }

  void _scheduleOverrideCleanup(List<int> removeAndroid, List<int> removeIos) {
    if (_cleanupScheduled) return;
    _cleanupScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanupScheduled = false;
      if (!mounted) return;

      setState(() {
        for (final id in removeAndroid) {
          _androidBuildOverride.remove(id);
          _androidErrOverride.remove(id);
        }
        for (final id in removeIos) {
          _iosBuildOverride.remove(id);
          _iosErrOverride.remove(id);
        }
      });
    });
  }

  double _maxContentWidth(double viewportWidth) {
    if (viewportWidth >= 1600) return 1400;
    if (viewportWidth >= 1400) return 1280;
    if (viewportWidth >= 1200) return 1100;
    return viewportWidth;
  }

  double _contentHPad(double viewportWidth) {
    if (viewportWidth < 360) return 8;
    if (viewportWidth < 420) return 10;
    if (viewportWidth < 600) return 12;
    return 16;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<OwnerProjectsBloc, OwnerProjectsState>(
        // ✅ Cleanup overrides AFTER frame (safe)
        listener: (context, state) {
          if (_androidBuildOverride.isEmpty && _iosBuildOverride.isEmpty) return;

          final removeAndroid = <int>[];
          final removeIos = <int>[];

          for (final p in state.filtered) {
            final id = p.linkId;

            final a = (p.androidBuildStatus ?? '').trim();
            final i = (p.iosBuildStatus ?? '').trim();

            if (_androidBuildOverride.containsKey(id) && a.isNotEmpty) {
              removeAndroid.add(id);
            }
            if (_iosBuildOverride.containsKey(id) && i.isNotEmpty) {
              removeIos.add(id);
            }
          }

          if (removeAndroid.isEmpty && removeIos.isEmpty) return;
          _scheduleOverrideCleanup(removeAndroid, removeIos);
        },
        child: Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final double maxContentWidth = _maxContentWidth(viewport.maxWidth);
                final double hPad = _contentHPad(viewport.maxWidth);

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Header(),
                          const SizedBox(height: 10),

                          // Search
                          BlocBuilder<OwnerProjectsBloc, OwnerProjectsState>(
                            builder: (context, state) {
                              final l10n = AppLocalizations.of(context)!;
                              return _SearchField(
                                l10n: l10n,
                                showFilters: _showFilters,
                                onToggleFilters: () {
                                  setState(() => _showFilters = !_showFilters);
                                },
                              );
                            },
                          ),

                          // Filters
                          if (_showFilters) ...[
                            const SizedBox(height: 10),
                            _FiltersBar(
                              l10n: AppLocalizations.of(context)!,
                              platform: _platform,
                              env: _env,
                              onPlatform: (v) {
                                setState(() {
                                  _platform = v;
                                  _visibleCount = _pageSize;
                                });
                              },
                              onEnv: (v) {
                                setState(() {
                                  _env = v;
                                  _visibleCount = _pageSize;
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 10),

                          // Content
                          Expanded(
                            child: BlocBuilder<OwnerProjectsBloc, OwnerProjectsState>(
                              builder: (context, state) {
                                final l10n = AppLocalizations.of(context)!;

                                final filtered = state.filtered
                                    .where(_matchPlatform)
                                    .where(_matchEnv)
                                    .toList();

                                final int total = filtered.length;
                                final int visible =
                                    total == 0 ? 0 : _visibleCount.clamp(0, total);

                                return RefreshIndicator(
                                  onRefresh: _refresh,
                                  child: () {
                                    if (state.loading) {
                                      return const _ListSkeleton(count: 6);
                                    }

                                    if (state.error != null) {
                                      return ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          const SizedBox(height: 80),
                                          _CenteredMessage(
                                            icon: Icons.error_outline_rounded,
                                            label: state.error!,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                        ],
                                      );
                                    }

                                    if (total == 0) {
                                      return ListView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          const SizedBox(height: 60),
                                          _EmptyProjects(l10n: l10n),
                                        ],
                                      );
                                    }

                                    return ListView.separated(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.only(bottom: 12),
                                      itemCount: visible + 1,
                                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                                      itemBuilder: (context, index) {
                                        // Footer
                                        if (index == visible) {
                                          if (visible < total) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Center(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _visibleCount =
                                                          (_visibleCount + _pageSize)
                                                              .clamp(0, total);
                                                    });
                                                  },
                                                  icon: const Icon(Icons.expand_more_rounded),
                                                  label: Text(l10n.owner_projects_load_more),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox(height: 6);
                                        }

                                        final item = filtered[index];

                                        return ProjectTile(
                                          project: item,
                                          serverRootNoApi: _serverRootNoApi(widget.dio),
                                          publishApi: _publishApi,
                                          onRebuildAndroid: (ctx, p) =>
                                              _rebuildAndroid(ctx, p),
                                          onRebuildIos: (ctx, p) => _rebuildIos(ctx, p),
                                          androidBuildStatusOverride:
                                              _androidBuildOverride[item.linkId],
                                          iosBuildStatusOverride:
                                              _iosBuildOverride[item.linkId],
                                          androidBuildErrorOverride:
                                              _androidErrOverride[item.linkId],
                                          iosBuildErrorOverride:
                                              _iosErrOverride[item.linkId],
                                        );
                                      },
                                    );
                                  }(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// UI widgets
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            l10n.owner_projects_title,
            maxLines: 1,
            minFontSize: 16,
            stepGranularity: 0.5,
            overflow: TextOverflow.ellipsis,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final AppLocalizations l10n;

  final _PlatformReadyFilter platform;
  final _EnvironmentFilter env;
  final ValueChanged<_PlatformReadyFilter> onPlatform;
  final ValueChanged<_EnvironmentFilter> onEnv;

  const _FiltersBar({
    required this.l10n,
    required this.platform,
    required this.env,
    required this.onPlatform,
    required this.onEnv,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final w = MediaQuery.of(context).size.width;

    final bool compact = w < 420;
    final bool ultraCompact = w < 360;

    final double pillHPad = ultraCompact ? 12 : (compact ? 14 : 16);
    final double pillVPad = ultraCompact ? 9 : (compact ? 10 : 11);
    final double fontSize = ultraCompact ? 12.5 : (compact ? 13.5 : 14);

    Widget group({
      required String title,
      required List<Widget> pills,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface.withOpacity(.85),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 10, runSpacing: 10, children: pills),
        ],
      );
    }

    final platformGroup = group(
      title: l10n.owner_projects_filter_platform_ready,
      pills: [
        _PillSeg(
          text: l10n.owner_projects_filter_all,
          selected: platform == _PlatformReadyFilter.all,
          onTap: () => onPlatform(_PlatformReadyFilter.all),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: l10n.owner_projects_filter_android,
          selected: platform == _PlatformReadyFilter.android,
          onTap: () => onPlatform(_PlatformReadyFilter.android),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: l10n.owner_projects_filter_ios,
          selected: platform == _PlatformReadyFilter.ios,
          onTap: () => onPlatform(_PlatformReadyFilter.ios),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
      ],
    );

    final envGroup = group(
      title: l10n.owner_projects_filter_environment,
      pills: [
        _PillSeg(
          text: l10n.owner_projects_filter_all,
          selected: env == _EnvironmentFilter.all,
          onTap: () => onEnv(_EnvironmentFilter.all),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: l10n.owner_projects_filter_local,
          selected: env == _EnvironmentFilter.local,
          onTap: () => onEnv(_EnvironmentFilter.local),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: l10n.owner_projects_filter_test,
          selected: env == _EnvironmentFilter.test,
          onTap: () => onEnv(_EnvironmentFilter.test),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: l10n.owner_projects_filter_production,
          selected: env == _EnvironmentFilter.production,
          onTap: () => onEnv(_EnvironmentFilter.production),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 820;
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                platformGroup,
                const SizedBox(height: 10),
                envGroup,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: platformGroup),
              const SizedBox(width: 14),
              Expanded(child: envGroup),
            ],
          );
        },
      ),
    );
  }
}

class _PillSeg extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  final double hPad;
  final double vPad;
  final double fontSize;

  const _PillSeg({
    required this.text,
    required this.selected,
    required this.onTap,
    required this.hPad,
    required this.vPad,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = selected ? cs.primary.withOpacity(.12) : Colors.transparent;
    final border = selected ? cs.primary : cs.outlineVariant.withOpacity(.8);
    final fg = selected ? cs.primary : cs.onSurface.withOpacity(.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: AutoSizeText(
          text,
          maxLines: 1,
          minFontSize: 10.5,
          stepGranularity: 0.5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final AppLocalizations l10n;
  final bool showFilters;
  final VoidCallback onToggleFilters;

  const _SearchField({
    required this.l10n,
    required this.showFilters,
    required this.onToggleFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        onChanged: (v) =>
            context.read<OwnerProjectsBloc>().add(OwnerProjectsSearchChanged(v)),
        style: tt.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: l10n.owner_projects_searchHint,
          filled: true,
          fillColor: cs.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary.withOpacity(.85), width: 1.3),
          ),
          suffixIcon: IconButton(
            onPressed: onToggleFilters,
            icon: Icon(
              showFilters ? Icons.close_rounded : Icons.tune_rounded,
              color: cs.onSurface.withOpacity(.75),
            ),
            tooltip: showFilters
                ? l10n.owner_projects_filters_hide
                : l10n.owner_projects_filters_show,
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _CenteredMessage({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: color ?? cs.onSurfaceVariant),
            const SizedBox(height: 12),
            AutoSizeText(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              minFontSize: 12,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyLarge?.copyWith(color: (color ?? cs.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyProjects({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.widgets_outlined, size: 60, color: cs.outline),
          const SizedBox(height: 10),
          AutoSizeText(
            l10n.owner_projects_emptyTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 13,
            stepGranularity: 0.5,
            overflow: TextOverflow.ellipsis,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          AutoSizeText(
            l10n.owner_projects_emptyBody,
            textAlign: TextAlign.center,
            maxLines: 4,
            minFontSize: 12,
            stepGranularity: 0.5,
            overflow: TextOverflow.ellipsis,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.7)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              context.read<OwnerNavCubit>().setIndex(0);
              context.go('/owner/home');
              AppToast.info(context, l10n.owner_projects_pick_template_first);
            },
            icon: const Icon(Icons.bolt_rounded),
            label: AutoSizeText(
              l10n.owner_home_requestApp,
              maxLines: 1,
              minFontSize: 12,
              stepGranularity: 0.5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final int count;
  const _ListSkeleton({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: count,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          height: 154,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(.5),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}