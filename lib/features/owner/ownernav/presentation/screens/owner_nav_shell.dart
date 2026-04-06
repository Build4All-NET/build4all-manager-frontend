import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/notifications_admin/data/service/admin_notifications_api.dart';
import 'package:build4all_manager/features/notifications_admin/presentation/cubit/admin_unread_count_cubit.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:build4all_manager/features/owner/ownernav/presentation/controllers/owner_nav_cubit.dart';
import '../widgets/owner_pill_nav_bar.dart';

enum OwnerMenuType { top, bottom, drawer }

OwnerMenuType _parseOwnerMenu(String? s) {
  switch ((s ?? '').toLowerCase().trim()) {
    case 'top':
      return OwnerMenuType.top;
    case 'drawer':
      return OwnerMenuType.drawer;
    case 'bottom':
    default:
      return OwnerMenuType.bottom;
  }
}

class OwnerDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const OwnerDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

class OwnerNavShell extends StatefulWidget {
  final String? backendMenuType;
  final OwnerMenuType? override;
  final List<OwnerDestination> destinations;
  final int initialIndex;
  final Widget child;

  const OwnerNavShell({
    super.key,
    required this.destinations,
    required this.child,
    this.backendMenuType,
    this.override,
    this.initialIndex = 0,
  });

  State<OwnerNavShell> createState() => _OwnerNavShellState();
}

class _OwnerNavShellState extends State<OwnerNavShell>
    with TickerProviderStateMixin {
  TabController? _tab;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  OwnerMenuType get _mode =>
      widget.override ?? _parseOwnerMenu(widget.backendMenuType);

  @override
  void initState() {
    super.initState();
    _syncCubitWithRouteIndex(widget.initialIndex);
    _attachTabIfNeeded(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant OwnerNavShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final destinationsChanged =
        oldWidget.destinations.length != widget.destinations.length ||
            oldWidget.override != widget.override ||
            oldWidget.backendMenuType != widget.backendMenuType;

    final routeIndexChanged = oldWidget.initialIndex != widget.initialIndex;

    if (destinationsChanged || routeIndexChanged) {
      _syncCubitWithRouteIndex(widget.initialIndex);
      _attachTabIfNeeded(widget.initialIndex);
    }
  }

  void _syncCubitWithRouteIndex(int routeIndex) {
    if (widget.destinations.isEmpty) return;

    final safeIndex = routeIndex.clamp(0, widget.destinations.length - 1);
    final cubit = context.read<OwnerNavCubit>();

    if (cubit.state.index != safeIndex) {
      cubit.setIndex(safeIndex);
    }
  }

  void _goTo(int i) {
    final pages = widget.destinations;
    if (pages.isEmpty) return;

    final safe = i.clamp(0, pages.length - 1);
    final dest = pages[safe];

    context.read<OwnerNavCubit>().setIndex(safe);

    final loc = GoRouterState.of(context).uri.toString();
    if (!loc.startsWith(dest.route)) {
      context.go(dest.route);
    }
  }

  void _attachTabIfNeeded(int currentIndex) {
    _tab?.dispose();
    if (widget.destinations.isEmpty) return;

    final safeIndex = currentIndex.clamp(0, widget.destinations.length - 1);

    if (_mode == OwnerMenuType.top) {
      _tab = TabController(length: widget.destinations.length, vsync: this)
        ..index = safeIndex
        ..addListener(() {
          if (_tab!.indexIsChanging) {
            _goTo(_tab!.index);
          }
        });
    } else {
      _tab = null;
    }
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.destinations;
    final width = MediaQuery.of(context).size.width;
    final useRail = width >= 900 && _mode == OwnerMenuType.bottom;

    return BlocProvider(
      create: (_) => AdminUnreadCountCubit(
        AdminNotificationsApi(DioClient.ensure()),
      )..start(),
      child: BlocBuilder<OwnerNavCubit, OwnerNavState>(
        builder: (context, navState) {
          final unreadCount =
              context.watch<AdminUnreadCountCubit>().state.count;

          final index =
              pages.isEmpty ? 0 : navState.index.clamp(0, pages.length - 1);

          if (_mode == OwnerMenuType.top && _tab != null && _tab!.index != index) {
            _tab!.index = index;
          }

          final body = AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(GoRouterState.of(context).uri.toString()),
              child: widget.child,
            ),
          );

          if (pages.isEmpty) {
            return Scaffold(
              key: _scaffoldKey,
              body: SafeArea(child: body),
            );
          }

          switch (_mode) {
            case OwnerMenuType.top:
              return Scaffold(
                key: _scaffoldKey,
                body: SafeArea(
                  child: Column(
                    children: [
                      if (_tab != null) _TopTabsStrip(tab: _tab!, pages: pages),
                      const SizedBox(height: 8),
                      Expanded(child: body),
                    ],
                  ),
                ),
              );

            case OwnerMenuType.drawer:
              return Scaffold(
                key: _scaffoldKey,
                drawer: _buildDrawer(context, pages, index),
                body: SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(child: body),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _FabHamburger(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      ),
                    ],
                  ),
                ),
              );

            case OwnerMenuType.bottom:
            default:
              if (useRail) {
                return Scaffold(
                  key: _scaffoldKey,
                  body: SafeArea(
                    child: Row(
                      children: [
                        _OwnerRail(
                          index: index,
                          onSelect: (i) => _goTo(i),
                          pages: pages,
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                );
              }

              return Scaffold(
                key: _scaffoldKey,
                body: SafeArea(child: body),
                bottomNavigationBar: OwnerPillNavBar(
                  currentIndex: index,
                  onTap: (i) => _goTo(i),
                  items: List.generate(pages.length, (i) {
                    final d = pages[i];
                    final iconData = (i == index) ? d.selectedIcon : d.icon;

                    final isNotificationsTab =
                        d.route.startsWith('/owner/notifications');

                    return OwnerPillNavItem(
                      icon: Icon(iconData),
                      label: d.label,
                      badgeCount: isNotificationsTab ? unreadCount : 0,
                    );
                  }),
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    List<OwnerDestination> pages,
    int index,
  ) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return NavigationDrawer(
      selectedIndex: index,
      onDestinationSelected: (i) {
        _goTo(i);
        Navigator.of(context).maybePop();
      },
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              l10n.owner_nav_drawer_title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        for (final d in pages)
          NavigationDrawerDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}

class _TopTabsStrip extends StatelessWidget {
  final TabController tab;
  final List<OwnerDestination> pages;
  const _TopTabsStrip({required this.tab, required this.pages});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.4)),
      ),
      child: AnimatedBuilder(
        animation: tab,
        builder: (context, _) {
          return TabBar(
            controller: tab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: [
              for (int i = 0; i < pages.length; i++)
                Tab(
                  icon: Icon(i == tab.index
                      ? pages[i].selectedIcon
                      : pages[i].icon),
                  text: pages[i].label,
                )
            ],
          );
        },
      ),
    );
  }
}

class _FabHamburger extends StatelessWidget {
  final VoidCallback onTap;
  const _FabHamburger({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: const StadiumBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Icon(Icons.menu, color: cs.onSurface),
        ),
      ),
    );
  }
}

class _OwnerRail extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final List<OwnerDestination> pages;

  const _OwnerRail({
    required this.index,
    required this.onSelect,
    required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final d in pages)
          NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
      ],
    );
  }
}