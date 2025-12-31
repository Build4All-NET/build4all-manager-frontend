// lib/features/owner/ownerrequests/presentation/widgets/runtime_section.dart
import 'package:flutter/material.dart';
import 'runtime_draft.dart';

/// ===============================================================
/// RuntimeSection (matches screenshot)
///
/// ✅ Menu Type: Bottom / Hamburger (affects preview through brandingJson)
/// ✅ Enabled Features: selected uses primary color, unselected uses inactive tint
/// ✅ Navigation: SIMPLE checkbox + label + drag handle (NO "=" / NO extra chip)
/// ✅ Home Sections: ONE LINE row (NO "full" / NO "=") + Limit pill + drag handle
///
/// NOTE:
/// - Preview changes are achieved because:
///   - navJson contains only enabled items (PhonePreview parses it)
///   - homeJson contains enabled sections in order (PhonePreview renders it)
///   - enabledFeaturesJson parsed by PhonePreview for a small feature row
/// ===============================================================
class RuntimeSection extends StatelessWidget {
  final RuntimeDraft draft;
  final ValueChanged<RuntimeDraft> onChanged;

  const RuntimeSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Runtime', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),

        // Menu Type
        _BlockCard(
          title: 'Menu Type',
          child: _MenuTypePills(
            value: draft.menuType,
            onChanged: (v) => onChanged(draft.copyWith(menuType: v)),
          ),
        ),
        const SizedBox(height: 12),

        // Enabled Features
        _BlockCard(
          title: 'Enabled Features',
          child: _FeaturesPills(
            selected: draft.enabledFeatures,
            onChanged: (set) => onChanged(draft.copyWith(enabledFeatures: set)),
          ),
        ),
        const SizedBox(height: 12),

        // Navigation
        _BlockCard(
          title: 'Navigation',
          subtitle:
              'Check/uncheck to show/hide in preview menu. Drag enabled items to reorder.',
          child: _NavEditorCompact(
            navItems: draft.navItems,
            onChanged: (list) => onChanged(draft.copyWith(navItems: list)),
          ),
        ),
        const SizedBox(height: 12),

        // Home Sections
        _BlockCard(
          title: 'Home Sections',
          subtitle:
              'Check/uncheck to show/hide in preview. Drag enabled sections to reorder.',
          child: _HomeEditorCompact(
            sections: draft.homeSections,
            onChanged: (list) => onChanged(draft.copyWith(homeSections: list)),
          ),
        ),

        const SizedBox(height: 6),
        Divider(color: cs.outlineVariant),
      ],
    );
  }
}

/// ===============================================================
/// Menu Type pills (Bottom / Hamburger)
/// ===============================================================
class _MenuTypePills extends StatelessWidget {
  final MenuType value;
  final ValueChanged<MenuType> onChanged;

  const _MenuTypePills({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget pill({
      required bool selected,
      required String text,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: selected ? cs.primary.withOpacity(.14) : cs.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? cs.primary.withOpacity(.45) : cs.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 18, color: selected ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(
          selected: value == MenuType.bottom,
          text: 'Bottom',
          icon: Icons.view_agenda_rounded,
          onTap: () => onChanged(MenuType.bottom),
        ),
        const SizedBox(width: 10),
        pill(
          selected: value == MenuType.hamburger,
          text: 'Hamburger',
          icon: Icons.menu_rounded,
          onTap: () => onChanged(MenuType.hamburger),
        ),
      ],
    );
  }
}

/// ===============================================================
/// Enabled Features pills (selected uses primary, unselected uses inactive tint)
/// ===============================================================
class _FeaturesPills extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _FeaturesPills({
    required this.selected,
    required this.onChanged,
  });

  static const all = [
    "ITEMS",
    "BOOKING",
    "REVIEWS",
    "ORDERS",
    "COUPONS",
    "NOTIFICATIONS",
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final activeBg = cs.primary;
    final activeFg = cs.onPrimary;

    // inactive tint (not white)
    final inactiveBg = cs.primary.withOpacity(.10);
    final inactiveBorder = cs.primary.withOpacity(.35);
    final inactiveFg = cs.primary.withOpacity(.85);

    return LayoutBuilder(
      builder: (context, c) {
        // Responsive columns (wide => 3, normal => 2)
        final cols = c.maxWidth >= 520 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: all.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2, // pill shape
          ),
          itemBuilder: (_, i) {
            final f = all[i];
            final isOn = selected.contains(f);

            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                final next = {...selected};
                if (next.contains(f)) {
                  next.remove(f);
                } else {
                  next.add(f);
                }
                onChanged(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOn ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isOn ? activeBg : inactiveBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded,
                        size: 16, color: isOn ? activeFg : inactiveFg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isOn ? activeFg : inactiveFg,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ===============================================================
/// Navigation editor (compact, no "=" no chips)
/// - enabled items are reorderable
/// - disabled items listed below
/// ===============================================================
class _NavEditorCompact extends StatelessWidget {
  final List<NavItemDraft> navItems;
  final ValueChanged<List<NavItemDraft>> onChanged;

  const _NavEditorCompact({
    required this.navItems,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = navItems.where((e) => e.enabled).toList();
    final disabled = navItems.where((e) => !e.enabled).toList();

    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: enabled.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            final enabledList = [...enabled];
            final item = enabledList.removeAt(oldIndex);
            enabledList.insert(newIndex, item);

            onChanged([...enabledList, ...disabled]);
          },
          itemBuilder: (ctx, i) {
            final item = enabled[i];
            return _NavRow(
              key: ValueKey(item.id),
              label: item.label,
              enabled: item.enabled,
              onToggle: (v) {
                final next = navItems
                    .map((x) =>
                        x.id == item.id ? x.copyWith(enabled: v) : x)
                    .toList();
                onChanged(next);
              },
            );
          },
        ),
        if (disabled.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...disabled.map(
            (item) => _NavRow(
              label: item.label,
              enabled: item.enabled,
              onToggle: (v) {
                final next = navItems
                    .map((x) => x.id == item.id ? x.copyWith(enabled: v) : x)
                    .toList();
                onChanged(next);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final ValueChanged<bool> onToggle;

  const _NavRow({
    super.key,
    required this.label,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Checkbox(
            value: enabled,
            onChanged: (v) => onToggle(v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ✅ small drag handle ONLY (no "=")
          Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// ===============================================================
/// Home sections editor (compact, one line)
/// ===============================================================
class _HomeEditorCompact extends StatelessWidget {
  final List<HomeSectionDraft> sections;
  final ValueChanged<List<HomeSectionDraft>> onChanged;

  const _HomeEditorCompact({
    required this.sections,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = sections.where((s) => s.enabled).toList();
    final disabled = sections.where((s) => !s.enabled).toList();

    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: enabled.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;
            final list = [...enabled];
            final item = list.removeAt(oldIndex);
            list.insert(newIndex, item);
            onChanged([...list, ...disabled]);
          },
          itemBuilder: (ctx, i) {
            final s = enabled[i];
            return _HomeRow(
              key: ValueKey(s.id),
              section: s,
              onToggle: (v) {
                onChanged(sections
                    .map((x) => x.id == s.id ? x.copyWith(enabled: v) : x)
                    .toList());
              },
              onLimitTap: () async {
                final next = await _pickLimit(context, s.limit);
                if (next != null) {
                  onChanged(sections
                      .map((x) => x.id == s.id ? x.copyWith(limit: next) : x)
                      .toList());
                }
              },
            );
          },
        ),
        if (disabled.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...disabled.map(
            (s) => _HomeRow(
              section: s,
              onToggle: (v) {
                onChanged(sections
                    .map((x) => x.id == s.id ? x.copyWith(enabled: v) : x)
                    .toList());
              },
              onLimitTap: () async {
                final next = await _pickLimit(context, s.limit);
                if (next != null) {
                  onChanged(sections
                      .map((x) => x.id == s.id ? x.copyWith(limit: next) : x)
                      .toList());
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<int?> _pickLimit(BuildContext context, int current) async {
    final values = [1, 2, 3, 5, 8, 10, 12, 16, 20];
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Pick limit', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final v in values)
              ListTile(
                title: Text('$v'),
                trailing: v == current ? const Icon(Icons.check_circle) : null,
                onTap: () => Navigator.pop(ctx, v),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeRow extends StatelessWidget {
  final HomeSectionDraft section;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLimitTap;

  const _HomeRow({
    super.key,
    required this.section,
    required this.onToggle,
    required this.onLimitTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Checkbox(
            value: section.enabled,
            onChanged: (v) => onToggle(v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Icon(_iconFor(section.type), size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _prettyType(section.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),

          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onLimitTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                'Limit ${section.limit}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  static IconData _iconFor(String type) {
    switch (type.toUpperCase()) {
      case 'HEADER':
        return Icons.view_day_rounded;
      case 'SEARCH':
        return Icons.search_rounded;
      case 'BANNER':
        return Icons.photo_library_outlined;
      case 'CATEGORY_CHIPS':
        return Icons.category_outlined;
      case 'ITEM_LIST':
        return Icons.view_carousel_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }

  static String _prettyType(String type) {
    final t = type.toUpperCase();
    switch (t) {
      case 'CATEGORY_CHIPS':
        return 'Categories';
      case 'ITEM_LIST':
        return 'Hero Items';
      case 'BANNER':
        return 'Hero Banner';
      default:
        final s = t.toLowerCase().replaceAll('_', ' ');
        return s.isEmpty ? type : '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }
}

/// ===============================================================
/// Block container
/// ===============================================================
class _BlockCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _BlockCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: cs.onSurface.withOpacity(.65),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
