import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/projects_screen.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/project_api.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/pro_kpi_card.dart';
import '../widgets/pro_project_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/header_hero.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Dio dio = DioClient.ensure();
    return BlocProvider(
      create: (_) => DashboardBloc(DashboardRepositoryImpl(ProjectApi(dio)))
        ..add(LoadDashboard()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // guard first frame
        if (state.overview == null) {
          return const _SkeletonLoader();
        }

        final ov = state.overview!;

        return RefreshIndicator(
          onRefresh: () async =>
              context.read<DashboardBloc>().add(RefreshDashboard()),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                stretch: true,
                elevation: 0,
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.fadeTitle
                  ],
                  background: const HeaderHero(),
                  titlePadding:
                      const EdgeInsetsDirectional.only(start: 16, bottom: 12),
                  title: Text(
                    l10n.dash_welcome,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),

              // KPIs
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverLayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = constraints.crossAxisExtent;
                    final cols = w > 980 ? 3 : (w > 620 ? 2 : 1);
                    final children = [
                      ProKpiCard(
                        icon: Icons.folder_copy_rounded,
                        label: l10n.dash_total_projects,
                        value: ov.totalProjects,
                        gradient: _g(context).primary,
                        delayMs: 0,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProjectsScreen()),
                          );
                        },
                      ),
                      ProKpiCard(
                        icon: Icons.check_circle_rounded,
                        label: l10n.dash_active_projects,
                        value: ov.activeProjects,
                        gradient: _g(context).success,
                        delayMs: 70,
                      ),
                      ProKpiCard(
                        icon: Icons.pause_circle_filled_rounded,
                        label: l10n.dash_inactive_projects,
                        value: ov.inactiveProjects,
                        gradient: _g(context).warning,
                        delayMs: 140,
                      ),
                    ];

                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => children[i],
                        childCount: children.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisExtent: 120,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                    );
                  },
                ),
              ),

              // Recent
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l10n.dash_recent_projects,
                  ),
                ),
              ),

              if (state.error != null && state.recent.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _InlineError(
                      message: state.error!,
                      onRetry: () =>
                          context.read<DashboardBloc>().add(LoadDashboard()),
                    ),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    child: state.recent.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(l10n.dash_no_recent),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.recent.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, thickness: .5),
                            itemBuilder: (_, i) =>
                                ProProjectTile(project: state.recent[i]),
                          ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
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
    return Container(
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: 180,
          flexibleSpace: const FlexibleSpaceBar(background: HeaderHero()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => _shimmerBox(cs),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: _shimmerList(cs)),
        ),
      ],
    );
  }

  Widget _shimmerBox(ColorScheme cs) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHigh,
            cs.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _shimmerList(ColorScheme cs) {
    return Card(
      elevation: 0,
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            height: 64,
            margin: EdgeInsets.only(bottom: i == 5 ? 0 : .5),
            color: cs.surfaceContainerHighest,
          ),
        ),
      ),
    );
  }
}

class _g {
  final Gradient primary, success, warning;
  _g._(this.primary, this.success, this.warning);

  factory _g(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _g._(
      LinearGradient(colors: [cs.primary, cs.secondary]),
      LinearGradient(colors: [cs.primary, cs.tertiary ?? cs.secondary]),
      LinearGradient(colors: [cs.secondary, cs.error]),
    );
  }
}
