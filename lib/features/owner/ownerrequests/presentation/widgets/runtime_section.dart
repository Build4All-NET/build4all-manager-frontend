import 'package:flutter/material.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'runtime_draft.dart';

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
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.owner_request_runtime_title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        _BlockCard(
          title: l10n.runtime_menu_type_title,
          child: _MenuTypePills(
            value: draft.menuType,
            onChanged: (v) => onChanged(draft.copyWith(menuType: v).normalized()),
          ),
        ),
        const SizedBox(height: 12),
        _BlockCard(
          title: l10n.runtime_enabled_features_title,
          child: _FeaturesPills(
            selected: draft.enabledFeatures,
            locked: RuntimeDraft.requiredFeaturesForRequiredNav(),
            onChanged: (set) =>
                onChanged(draft.copyWith(enabledFeatures: set).normalized()),
          ),
        ),
        const SizedBox(height: 12),
        _BlockCard(
          title: l10n.runtime_navigation_title,
          subtitle: l10n.runtime_navigation_subtitle,
          child: _NavEditorCompact(
            menuType: draft.menuType,
            enabledFeatures: draft.enabledFeatures,
            navItems: draft.navItems,
            onChanged: (list) =>
                onChanged(draft.copyWith(navItems: list).normalized()),
          ),
        ),
        const SizedBox(height: 12),
        _BlockCard(
          title: l10n.runtime_home_sections_title,
          subtitle: l10n.runtime_home_sections_subtitle,
          child: _HomeEditorCompact(
            sections: draft.homeSections,
            onChanged: (list) =>
                onChanged(draft.copyWith(homeSections: list).normalized()),
          ),
        ),
        const SizedBox(height: 6),
        Divider(color: cs.outlineVariant),
      ],
    );
  }
}

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
    final l10n = AppLocalizations.of(context)!;

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
                Icon(
                  icon,
                  size: 18,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
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
          text: l10n.runtime_menu_bottom,
          icon: Icons.view_agenda_rounded,
          onTap: () => onChanged(MenuType.bottom),
        ),
        const SizedBox(width: 10),
        pill(
          selected: value == MenuType.hamburger,
          text: l10n.runtime_menu_hamburger,
          icon: Icons.menu_rounded,
          onTap: () => onChanged(MenuType.hamburger),
        ),
      ],
    );
  }
}

class _FeaturesPills extends StatelessWidget {
  final Set<String> selected;
  final Set<String> locked;
  final ValueChanged<Set<String>> onChanged;

  const _FeaturesPills({
    required this.selected,
    required this.locked,
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

  String _featureLabel(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code.toUpperCase()) {
      case 'ITEMS':
        return l10n.runtime_feature_items;
      case 'BOOKING':
        return l10n.runtime_feature_booking;
      case 'REVIEWS':
        return l10n.runtime_feature_reviews;
      case 'ORDERS':
        return l10n.runtime_feature_orders;
      case 'COUPONS':
        return l10n.runtime_feature_coupons;
      case 'NOTIFICATIONS':
        return l10n.runtime_feature_notifications;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final activeBg = cs.primary;
    final activeFg = cs.onPrimary;

    final inactiveBg = cs.primary.withOpacity(.10);
    final inactiveBorder = cs.primary.withOpacity(.35);
    final inactiveFg = cs.primary.withOpacity(.85);

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 520 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: all.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.2,
          ),
          itemBuilder: (_, i) {
            final f = all[i];
            final isOn = selected.contains(f);
            final isLocked = locked.contains(f);

            return Opacity(
              opacity: isLocked ? 0.75 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: isLocked
                    ? null
                    : () {
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
                      Icon(
                        isLocked ? Icons.lock_rounded : Icons.check_rounded,
                        size: 16,
                        color: isOn ? activeFg : inactiveFg,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _featureLabel(context, f),
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
              ),
            );
          },
        );
      },
    );
  }
}

class _NavEditorCompact extends StatelessWidget {
  final MenuType menuType;
  final Set<String> enabledFeatures;
  final List<NavItemDraft> navItems;
  final ValueChanged<List<NavItemDraft>> onChanged;

  const _NavEditorCompact({
    required this.menuType,
    required this.enabledFeatures,
    required this.navItems,
    required this.onChanged,
  });

  String _featureLabel(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code.toUpperCase()) {
      case 'ITEMS':
        return l10n.runtime_feature_items;
      case 'BOOKING':
        return l10n.runtime_feature_booking;
      case 'REVIEWS':
        return l10n.runtime_feature_reviews;
      case 'ORDERS':
        return l10n.runtime_feature_orders;
      case 'COUPONS':
        return l10n.runtime_feature_coupons;
      case 'NOTIFICATIONS':
        return l10n.runtime_feature_notifications;
      default:
        return code;
    }
  }

  String _navLabel(BuildContext context, NavItemDraft item) {
    final l10n = AppLocalizations.of(context)!;
    switch (item.id.toUpperCase()) {
      case 'HOME':
        return l10n.preview_phone_nav_home;
      case 'EXPLORE':
        return l10n.preview_phone_nav_explore;
      case 'CART':
        return l10n.preview_phone_nav_cart;
      case 'PROFILE':
        return l10n.preview_phone_nav_profile;
      default:
        return item.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = navItems.where((e) => e.enabled).toList();
    final disabled = navItems.where((e) => !e.enabled).toList();

    bool bottomMaxReachedForEnable() =>
        menuType == MenuType.bottom && enabled.length >= RuntimeDraft.bottomNavMax;

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
            final required = RuntimeDraft.navIsRequired(item.id);

            return _NavRow(
              key: ValueKey(item.id),
              label: _navLabel(context, item),
              enabled: true,
              helper: required ? l10n.runtime_required : null,
              onToggle: (v) {
                if (!v && required) return;
                final next = navItems
                    .map((x) => x.id == item.id ? x.copyWith(enabled: v) : x)
                    .toList();
                onChanged(next);
              },
            );
          },
        ),
        if (disabled.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...disabled.map((item) {
            final required = RuntimeDraft.navIsRequired(item.id);
            final missing = RuntimeDraft.navMissingFeatures(item.id, enabledFeatures);
            final lockEnable =
                required || missing.isNotEmpty || bottomMaxReachedForEnable();

            final helper = required
                ? l10n.runtime_required
                : (missing.isNotEmpty
                    ? l10n.runtime_requires_features(
                        missing.map((e) => _featureLabel(context, e)).join(', '),
                      )
                    : (bottomMaxReachedForEnable()
                        ? l10n.runtime_max_bottom_tabs(
                            RuntimeDraft.bottomNavMax.toString(),
                          )
                        : null));

            return _NavRow(
              label: _navLabel(context, item),
              enabled: false,
              helper: helper,
              onToggle: (v) {
                if (v && lockEnable) return;
                final next = navItems
                    .map((x) => x.id == item.id ? x.copyWith(enabled: v) : x)
                    .toList();
                onChanged(next);
              },
            );
          }),
        ],
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final String? helper;
  final ValueChanged<bool> onToggle;

  const _NavRow({
    super.key,
    required this.label,
    required this.enabled,
    required this.onToggle,
    this.helper,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helper!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withOpacity(.55),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.drag_handle_rounded, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

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
                onChanged(
                  sections
                      .map((x) => x.id == s.id ? x.copyWith(enabled: v) : x)
                      .toList(),
                );
              },
              onLimitTap: () async {
                final next = await _pickLimit(context, s.limit);
                if (next != null) {
                  onChanged(
                    sections
                        .map((x) => x.id == s.id ? x.copyWith(limit: next) : x)
                        .toList(),
                  );
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
                onChanged(
                  sections
                      .map((x) => x.id == s.id ? x.copyWith(enabled: v) : x)
                      .toList(),
                );
              },
              onLimitTap: () async {
                final next = await _pickLimit(context, s.limit);
                if (next != null) {
                  onChanged(
                    sections
                        .map((x) => x.id == s.id ? x.copyWith(limit: next) : x)
                        .toList(),
                  );
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<int?> _pickLimit(BuildContext context, int current) async {
    final l10n = AppLocalizations.of(context)!;
    final values = [1, 2, 3, 5, 8, 10, 12, 16, 20];

    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.runtime_pick_limit,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            for (final v in values)
              ListTile(
                title: Text(l10n.runtime_limit_value(v.toString())),
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

  String _prettyType(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    final t = type.toUpperCase();

    switch (t) {
      case 'HEADER':
        return l10n.runtime_section_header;
      case 'SEARCH':
        return l10n.runtime_section_search;
      case 'BANNER':
        return l10n.runtime_section_banner;
      case 'CATEGORY_CHIPS':
        return l10n.runtime_section_categories;
      case 'ITEM_LIST':
        return l10n.runtime_section_hero_items;
      default:
        final s = t.toLowerCase().replaceAll('_', ' ');
        return s.isEmpty ? type : '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
              _prettyType(context, section.type),
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
                l10n.runtime_limit_value(section.limit.toString()),
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
}

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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
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