import 'package:build4all_manager/features/owner/common/data/repositories/owner_repository_impl.dart';
import 'package:build4all_manager/features/owner/common/data/services/owner_api.dart';
import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';
import 'package:build4all_manager/features/owner/common/domain/usecases/get_my_apps_uc.dart';
import 'package:build4all_manager/features/owner/ownerprojects/presentation/widgets/project_tile.dart';
import 'package:build4all_manager/features/owner/publish/data/services/owner_publish_api.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final repo = OwnerRepositoryImpl(OwnerApi(widget.dio));

    String serverRootNoApi(Dio d) {
      final base = d.options.baseUrl; // e.g. http://host:8080/api
      return base.replaceFirst(RegExp(r'/api/?$'), '');
    }

    Future<void> refresh(BuildContext ctx) async {
      ctx.read<OwnerProjectsBloc>().add(OwnerProjectsStarted(widget.ownerId));
      setState(() => _visibleCount = _pageSize);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    Future<void> rebuildAndRefresh(BuildContext ctx, OwnerProject p) async {
      try {
        await repo.rebuildAppLink(ownerId: widget.ownerId, linkId: p.linkId);

        if (ctx.mounted) {
          AppToast.success(ctx, 'Rebuild queued');
        }

        ctx
            .read<OwnerProjectsBloc>()
            .add(OwnerProjectsRefreshed(widget.ownerId));
      } catch (e) {
        if (ctx.mounted) {
          AppToast.error(ctx, 'Rebuild failed: $e');
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

      final s = p.status.toLowerCase(); // ✅ FIX (status non-nullable)
      if (_env == _EnvironmentFilter.local) return s.contains('local');
      if (_env == _EnvironmentFilter.test) return s.contains('test');
      if (_env == _EnvironmentFilter.production) {
        return s.contains('prod') || s.contains('production');
      }
      return true;
    }

    return BlocProvider(
      create: (_) => OwnerProjectsBloc(getMyApps: GetMyAppsUc(repo))
        ..add(OwnerProjectsStarted(widget.ownerId)),
      child: Scaffold(
        backgroundColor: cs.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final double maxContentWidth =
                  _maxContentWidth(viewport.maxWidth);
              final double hPad = _contentHPad(viewport.maxWidth);

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: BlocBuilder<OwnerProjectsBloc, OwnerProjectsState>(
                      builder: (context, state) {
                        final l10n = AppLocalizations.of(context)!;
                        final double bottomPad = 12;

                        final filtered = state.filtered
                            .where(_matchPlatform)
                            .where(_matchEnv)
                            .toList();

                        final int total = filtered.length;
                        final int visible =
                            total == 0 ? 0 : _visibleCount.clamp(0, total);

                        return RefreshIndicator(
                          onRefresh: () => refresh(context),
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              const SliverToBoxAdapter(child: _Header()),
                              const SliverToBoxAdapter(
                                  child: SizedBox(height: 10)),
                              SliverToBoxAdapter(
                                child: _SearchField(
                                  l10n: l10n,
                                  showFilters: _showFilters,
                                  onToggleFilters: () {
                                    setState(
                                        () => _showFilters = !_showFilters);
                                  },
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: _showFilters
                                      ? Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: _FiltersBar(
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
                                        )
                                      : const SizedBox(height: 0),
                                ),
                              ),
                              const SliverToBoxAdapter(
                                  child: SizedBox(height: 10)),
                              if (state.loading) ...[
                                SliverPadding(
                                  padding: EdgeInsets.only(bottom: bottomPad),
                                  sliver: const _ListSkeleton(count: 6),
                                ),
                              ] else if (state.error != null) ...[
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _CenteredMessage(
                                    icon: Icons.error_outline_rounded,
                                    label: state.error!,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ] else if (total == 0) ...[
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _EmptyProjects(l10n: l10n),
                                ),
                              ] else ...[
                                SliverPadding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final item = filtered[index];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 6),
                                          child: ProjectTile(
                                            project: item,
                                            serverRootNoApi:
                                                serverRootNoApi(widget.dio),
                                            publishApi:
                                                OwnerPublishApi(widget.dio),
                                          ),
                                        );
                                      },
                                      childCount: visible,
                                    ),
                                  ),
                                ),
                                if (visible < total)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: bottomPad,
                                        top: 2,
                                      ),
                                      child: Center(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _visibleCount =
                                                  (_visibleCount + _pageSize)
                                                      .clamp(0, total);
                                            });
                                          },
                                          icon: const Icon(
                                              Icons.expand_more_rounded),
                                          label: const Text('Load more'),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverToBoxAdapter(
                                      child: SizedBox(height: bottomPad)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.owner_projects_title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.owner_projects_searchHint,
            style:
                tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.65)),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final _PlatformReadyFilter platform;
  final _EnvironmentFilter env;
  final ValueChanged<_PlatformReadyFilter> onPlatform;
  final ValueChanged<_EnvironmentFilter> onEnv;

  const _FiltersBar({
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
      title: 'Platform Ready',
      pills: [
        _PillSeg(
          text: 'All',
          selected: platform == _PlatformReadyFilter.all,
          onTap: () => onPlatform(_PlatformReadyFilter.all),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: 'Android',
          selected: platform == _PlatformReadyFilter.android,
          onTap: () => onPlatform(_PlatformReadyFilter.android),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: 'iOS',
          selected: platform == _PlatformReadyFilter.ios,
          onTap: () => onPlatform(_PlatformReadyFilter.ios),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
      ],
    );

    final envGroup = group(
      title: 'Environment',
      pills: [
        _PillSeg(
          text: 'All',
          selected: env == _EnvironmentFilter.all,
          onTap: () => onEnv(_EnvironmentFilter.all),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: 'Local',
          selected: env == _EnvironmentFilter.local,
          onTap: () => onEnv(_EnvironmentFilter.local),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: 'Test',
          selected: env == _EnvironmentFilter.test,
          onTap: () => onEnv(_EnvironmentFilter.test),
          hPad: pillHPad,
          vPad: pillVPad,
          fontSize: fontSize,
        ),
        _PillSeg(
          text: 'Production',
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
        child: Text(
          text,
          maxLines: 1,
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
        onChanged: (v) => context
            .read<OwnerProjectsBloc>()
            .add(OwnerProjectsSearchChanged(v)),
        style: tt.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: l10n.owner_projects_searchHint,
          filled: true,
          fillColor: cs.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          suffixIcon: IconButton(
            onPressed: onToggleFilters,
            icon: Icon(
              showFilters ? Icons.close_rounded : Icons.tune_rounded,
              color: cs.onSurface.withOpacity(.75),
            ),
            tooltip: showFilters ? 'Hide filters' : 'Show filters',
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
            Text(
              label,
              textAlign: TextAlign.center,
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
          Text(
            l10n.owner_projects_emptyTitle,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.owner_projects_emptyBody,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.7)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed('/owner/request-new'),
            icon: const Icon(Icons.bolt_rounded),
            label: Text(l10n.owner_home_requestApp),
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            height: 154,
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(.5),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        childCount: count,
      ),
    );
  }
}
