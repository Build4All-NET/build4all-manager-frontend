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
      child: const _DashboardContent(),
    );
  }
}

/// ✅ CONTENT ONLY (NO Scaffold, NO AppBar, NO SliverAppBar)
class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.overview == null) {
          return const _SkeletonLoader();
        }

        final ov = state.overview!;

        return RefreshIndicator.adaptive(
          onRefresh: () async =>
              context.read<DashboardBloc>().add(RefreshDashboard()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // hero (instead of SliverAppBar)
              const HeaderHero(),
              const SizedBox(height: 14),

              // KPIs (responsive layout)
              LayoutBuilder(
                builder: (ctx, c) {
                  final w = c.maxWidth;
                  final cols = w > 980 ? 3 : (w > 620 ? 2 : 1);

                  final cards = [
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
                            builder: (_) => const ProjectsScreen(),
                          ),
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

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisExtent: 120,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (_, i) => cards[i],
                  );
                },
              ),

              const SizedBox(height: 14),
              SectionHeader(title: l10n.dash_recent_projects),
              const SizedBox(height: 10),

              if (state.error != null && state.recent.isEmpty)
                _InlineError(
                  message: state.error!,
                  onRetry: () =>
                      context.read<DashboardBloc>().add(LoadDashboard()),
                ),

              Card(
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          TextButton(onPressed: onRetry, child: Text(l10n.common_retry)),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const HeaderHero(),
        const SizedBox(height: 14),
        _shimmerBox(cs),
        const SizedBox(height: 12),
        _shimmerBox(cs),
        const SizedBox(height: 12),
        _shimmerBox(cs),
        const SizedBox(height: 14),
        _shimmerList(cs),
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
