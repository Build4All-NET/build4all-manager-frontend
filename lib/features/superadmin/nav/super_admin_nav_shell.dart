import 'package:build4all_manager/features/notifications_admin/presentation/widgets/admin_notification_bell.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum SuperMenuType { top, bottom, drawer }

SuperMenuType _parseMenu(String? s) {
  switch ((s ?? '').toLowerCase().trim()) {
    case 'top':
      return SuperMenuType.top;
    case 'drawer':
      return SuperMenuType.drawer;
    case 'bottom':
    default:
      return SuperMenuType.bottom;
  }
}

class SuperAdminDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  const SuperAdminDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}

class SuperAdminNavShell extends StatefulWidget {
  final String? backendMenuType;
  final SuperMenuType? override;
  final List<SuperAdminDestination> destinations;
  final int initialIndex;

  const SuperAdminNavShell({
    super.key,
    required this.destinations,
    this.backendMenuType,
    this.override,
    this.initialIndex = 0,
  });


  State<SuperAdminNavShell> createState() => _SuperAdminNavShellState();
}

class _SuperAdminNavShellState extends State<SuperAdminNavShell>
    with TickerProviderStateMixin {
  late int _index;
  TabController? _tab;

  SuperMenuType get _mode =>
      widget.override ?? _parseMenu(widget.backendMenuType);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _syncTabController();
    _clampIndex();
  }

  @override
  void didUpdateWidget(covariant SuperAdminNavShell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final menuChanged = oldWidget.override != widget.override ||
        oldWidget.backendMenuType != widget.backendMenuType;

    final lenChanged =
        oldWidget.destinations.length != widget.destinations.length;

    if (menuChanged || lenChanged) {
      _syncTabController();
      _clampIndex();
    }
  }

  void _clampIndex() {
    if (widget.destinations.isEmpty) {
      if (_index != 0) {
        setState(() => _index = 0);
      }
      return;
    }

    final max = widget.destinations.length - 1;
    final safe = _index.clamp(0, max);

    if (safe != _index) {
      setState(() => _index = safe);
    }

    if (_mode == SuperMenuType.top && _tab != null && _tab!.index != safe) {
      _tab!.index = safe;
    }
  }

  void _syncTabController() {
    _tab?.dispose();
    _tab = null;

    if (_mode == SuperMenuType.top && widget.destinations.isNotEmpty) {
      _tab = TabController(length: widget.destinations.length, vsync: this);

      _tab!.addListener(() {
        if (_tab!.indexIsChanging) return;
        if (!mounted) return;

        final safe = _tab!.index.clamp(0, widget.destinations.length - 1);
        if (safe != _index) {
          setState(() => _index = safe);
        }
      });

      final safe = _index.clamp(0, widget.destinations.length - 1);
      _tab!.index = safe;
    }
  }

  @override
  void dispose() {
    _tab?.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    if (widget.destinations.isEmpty) return;

    final safe = i.clamp(0, widget.destinations.length - 1);
    if (safe == _index) return;

    setState(() => _index = safe);

    if (_mode == SuperMenuType.top && _tab != null && _tab!.index != safe) {
      _tab!.animateTo(safe);
    }
  }

  String _title(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.destinations.isEmpty) return l10n.nav_super_admin;

    return widget
        .destinations[_index.clamp(0, widget.destinations.length - 1)].label;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final notificationsIndex = widget.destinations.indexWhere(
      (d) => d.label == l10n.super_nav_notifications,
    );

    return AppBar(
      titleSpacing: 14,
      title: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(
              _title(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
      actions: [
        if (notificationsIndex != -1)
          AdminNotificationBell(
            onTap: () async {
              _goTo(notificationsIndex);
            },
          ),
        const SizedBox(width: 6),
      ],
      bottom: (_mode == SuperMenuType.top && _tab != null)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(54),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tab,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerHeight: 0,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                  tabs: [
                    for (final d in widget.destinations)
                      Tab(
                        text: d.label,
                        icon: Icon(d.icon),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBodyStack(List<SuperAdminDestination> pages) {
    return Stack(
      children: [
        IndexedStack(
          index: _index,
          children: [
            for (final d in pages)
              KeyedSubtree(
                key: ValueKey(d.label),
                child: d.page,
              ),
          ],
        ),
        IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Container(
              key: ValueKey(_index),
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = widget.destinations;

    if (pages.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(l10n.nav_super_admin),
        ),
      );
    }

    switch (_mode) {
      case SuperMenuType.top:
        return Scaffold(
          appBar: _buildAppBar(context),
          body: TabBarView(
            controller: _tab,
            children: [for (final d in pages) d.page],
          ),
        );

      case SuperMenuType.drawer:
        return Scaffold(
          appBar: _buildAppBar(context),
          drawer: _buildDrawer(context, pages),
          body: _buildBodyStack(pages),
        );

      case SuperMenuType.bottom:
      default:
        return Scaffold(
          appBar: _buildAppBar(context),
          body: _buildBodyStack(pages),
          bottomNavigationBar: _ProBottomBar(
            index: _index,
            onTap: _goTo,
            destinations: pages,
          ),
        );
    }
  }

  Widget _buildDrawer(BuildContext context, List<SuperAdminDestination> pages) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return NavigationDrawer(
      selectedIndex: _index,
      onDestinationSelected: (i) {
        _goTo(i);
        Navigator.of(context).maybePop();
      },
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.onPrimary.withOpacity(.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: cs.onPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.nav_super_admin,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final d in pages)
          NavigationDrawerDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: Text(d.label),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ProBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<SuperAdminDestination> destinations;

  const _ProBottomBar({
    required this.index,
    required this.onTap,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.0),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 68,
                  labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                    (states) {
                      return const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                      );
                    },
                  ),
                  iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
                    (states) {
                      final selected = states.contains(MaterialState.selected);
                      return IconThemeData(
                        size: selected ? 21 : 20,
                      );
                    },
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: onTap,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(
                        icon: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(d.icon),
                        ),
                        selectedIcon: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(d.selectedIcon),
                        ),
                        label: d.label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}