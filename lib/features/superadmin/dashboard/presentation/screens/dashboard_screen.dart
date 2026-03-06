import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/services/licensing_api.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/apps_licenses_screen.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/projects_screen.dart';
import 'package:build4all_manager/features/superadmin/dashboard/presentation/screens/upgrade_requests_screen.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/services/project_api.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/header_hero.dart';
import '../widgets/pro_kpi_card.dart';
import '../widgets/pro_project_tile.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Dio dio = DioClient.ensure();

    return BlocProvider(
      create: (_) => DashboardBloc(
        DashboardRepositoryImpl(
          ProjectApi(dio),
          LicensingApi(dio),
        ),
      )..add(LoadDashboard()),
      child: const _DashboardContent(),
    );
  }
}

/// CONTENT ONLY
class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.overview == null) {
          if (state.error != null) {
            return _FullPageError(
              message: state.error!,
              onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()),
            );
          }
          return const _SkeletonLoader();
        }

        final ov = state.overview!;

        return RefreshIndicator.adaptive(
          onRefresh: () async {
            context.read<DashboardBloc>().add(RefreshDashboard());
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _HeroBox(),
              const SizedBox(height: 14),

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

              const SizedBox(height: 12),

              _ProWideKpiCard(
                icon: Icons.upgrade_rounded,
                label: l10n.dash_upgrade_requests,
                subtitle: l10n.upgrade_requests_hint,
                value: ov.pendingUpgradeRequests,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.primary,
                  ],
                ),
                delayMs: 210,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SuperAdminUpgradeRequestsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _ProWideKpiCard(
                icon: Icons.verified_user_rounded,
                label: l10n.appLicensesTitle,
                subtitle: l10n.appLicensesSubtitle,
                value: ov.totalProjects,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                delayMs: 260,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AppsLicensesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),
              SectionHeader(title: l10n.dash_recent_projects),
              const SizedBox(height: 10),

              if (state.error != null && state.recent.isEmpty)
                _InlineError(
                  message: state.error!,
                  onRetry: () => context.read<DashboardBloc>().add(LoadDashboard()),
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
                        itemBuilder: (_, i) => ProProjectTile(
                          project: state.recent[i],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBox extends StatelessWidget {
  const _HeroBox();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = w < 380 ? 150.0 : 180.0;

    return SizedBox(
      height: h,
      width: double.infinity,
      child: const HeaderHero(),
    );
  }
}

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FullPageError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: cs.error, size: 46),
            const SizedBox(height: 10),
            Text(
              l10n.common_error,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

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
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.common_retry),
          ),
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
        const _HeroBox(),
        const SizedBox(height: 14),
        _shimmerBox(cs),
        const SizedBox(height: 12),
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
  final Gradient primary;
  final Gradient success;
  final Gradient warning;

  _g._(this.primary, this.success, this.warning);

  factory _g(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _g._(
      LinearGradient(colors: [cs.primary, cs.secondary]),
      LinearGradient(colors: [cs.primary, cs.tertiary]),
      LinearGradient(colors: [cs.secondary, cs.error]),
    );
  }
}

class _ProWideKpiCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final int value;
  final Gradient gradient;
  final int delayMs;
  final VoidCallback? onTap;

  const _ProWideKpiCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.gradient,
    this.delayMs = 0,
    this.onTap,
  });

  @override
  State<_ProWideKpiCard> createState() => _ProWideKpiCardState();
}

class _ProWideKpiCardState extends State<_ProWideKpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  late final Animation<double> _scale =
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

  bool _hover = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tappable = widget.onTap != null;

    return ScaleTransition(
      scale: _scale,
      child: MouseRegion(
        cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => tappable ? setState(() => _hover = true) : null,
        onExit: (_) => tappable ? setState(() => _hover = false) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hover ? .12 : .08),
                  blurRadius: _hover ? 18 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(_hover ? .20 : .12),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: _hover ? 1 : 0,
                      child: Container(
                        color: Colors.white.withOpacity(.06),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(widget.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DefaultTextStyle(
                            style: const TextStyle(color: Colors.white),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .2,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.value}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            if (tappable) ...[
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}