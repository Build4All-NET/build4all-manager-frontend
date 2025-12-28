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
  final String? backendMenuType; // "top" | "bottom" | "drawer"
  final SuperMenuType? override; // set this to force a mode locally
  final List<SuperAdminDestination> destinations;

  const SuperAdminNavShell({
    super.key,
    required this.destinations,
    this.backendMenuType,
    this.override,
  });


  State<SuperAdminNavShell> createState() => _SuperAdminNavShellState();
}

class _SuperAdminNavShellState extends State<SuperAdminNavShell>
    with TickerProviderStateMixin {
  int _index = 0;
  TabController? _tab;

  SuperMenuType get _mode =>
      widget.override ?? _parseMenu(widget.backendMenuType);

  @override
  void initState() {
    super.initState();
    _maybeAttachTabController();
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
      _maybeAttachTabController();
      _clampIndex();
    }
  }

  void _clampIndex() {
    if (widget.destinations.isEmpty) {
      if (_index != 0) setState(() => _index = 0);
      return;
    }

    if (_index < 0 || _index >= widget.destinations.length) {
      setState(() => _index = 0);
    }

    // keep TabController in sync if mode is top
    if (_mode == SuperMenuType.top && _tab != null) {
      final safe = _index.clamp(0, widget.destinations.length - 1);
      if (_tab!.index != safe) {
        _tab!.index = safe;
      }
    }
  }

  void _maybeAttachTabController() {
    _tab?.dispose();

    if (_mode == SuperMenuType.top && widget.destinations.isNotEmpty) {
      _tab = TabController(length: widget.destinations.length, vsync: this);

      // keep _index updated when user taps tab
      _tab!.addListener(() {
        if (_tab!.indexIsChanging) return;
        if (mounted) setState(() => _index = _tab!.index);
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

  void _goTo(int i) {
    if (widget.destinations.isEmpty) return;

    final safe = i.clamp(0, widget.destinations.length - 1);
    setState(() => _index = safe);

    if (_mode == SuperMenuType.top && _tab != null && _tab!.index != safe) {
      _tab!.animateTo(safe);
    }
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final titleText = widget.destinations.isEmpty
        ? l10n.nav_super_admin
        : widget.destinations[_index.clamp(0, widget.destinations.length - 1)]
            .label;

    return AppBar(
      titleSpacing: 12,
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
              titleText,
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
        IconButton(
          tooltip: l10n.nav_dashboard,
          onPressed: () => _goTo(0),
          icon: const Icon(Icons.dashboard_customize_rounded),
        ),
        const SizedBox(width: 6),
      ],
      bottom: (_mode == SuperMenuType.top && _tab != null)
          ? TabBar(
              controller: _tab,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final d in widget.destinations)
                  Tab(text: d.label, icon: Icon(d.icon)),
              ],
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.destinations;

    if (pages.isEmpty) {
      return Scaffold(
        appBar: _appBar(context),
        body: const Center(child: Text("No destinations configured")),
      );
    }

    switch (_mode) {
      case SuperMenuType.top:
        return Scaffold(
          appBar: _appBar(context),
          body: TabBarView(
            controller: _tab,
            children: [for (final d in pages) d.page],
          ),
        );

      case SuperMenuType.drawer:
        return Scaffold(
          appBar: _appBar(context),
          drawer: _buildDrawer(context, pages),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: IndexedStack(
              key: ValueKey(_index),
              index: _index,
              children: [for (final d in pages) d.page],
            ),
          ),
        );

      case SuperMenuType.bottom:
      default:
        return Scaffold(
          appBar: _appBar(context),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: IndexedStack(
              key: ValueKey(_index),
              index: _index,
              children: [for (final d in pages) d.page],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            height: 72,
            selectedIndex: _index,
            onDestinationSelected: _goTo,
            destinations: [
              for (final d in pages)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
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
              l10n.nav_super_admin,
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
