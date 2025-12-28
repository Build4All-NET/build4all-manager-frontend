import 'package:flutter/material.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Runtime Config', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _Card(
          child: _MenuTypePicker(
            value: draft.menuType,
            onChanged: (v) => onChanged(draft.copyWith(menuType: v)),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: _BrandingFlags(
            splashMode: draft.splashMode,
            showSearchOnExplore: draft.showSearchOnExplore,
            onSplashMode: (v) => onChanged(draft.copyWith(splashMode: v)),
            onSearchExplore: (v) =>
                onChanged(draft.copyWith(showSearchOnExplore: v)),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: _FeaturesPicker(
            selected: draft.enabledFeatures,
            onChanged: (set) => onChanged(draft.copyWith(enabledFeatures: set)),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: _NavEditor(
            navItems: draft.navItems,
            onChanged: (list) => onChanged(draft.copyWith(navItems: list)),
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: _HomeEditor(
            sections: draft.homeSections,
            onChanged: (list) => onChanged(draft.copyWith(homeSections: list)),
          ),
        ),
        const SizedBox(height: 12),
        _GeneratedPreview(
          out: draft.toJsonOut(),
          borderColor: cs.outlineVariant,
        ),
      ],
    );
  }
}

class _MenuTypePicker extends StatelessWidget {
  final MenuType value;
  final ValueChanged<MenuType> onChanged;

  const _MenuTypePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<MenuType>(
          segments: const [
            ButtonSegment(value: MenuType.bottom, label: Text('Bottom')),
            ButtonSegment(value: MenuType.drawer, label: Text('Drawer')),
          ],
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
        ),
      ],
    );
  }
}

class _BrandingFlags extends StatelessWidget {
  final String splashMode;
  final bool showSearchOnExplore;
  final ValueChanged<String> onSplashMode;
  final ValueChanged<bool> onSearchExplore;

  const _BrandingFlags({
    required this.splashMode,
    required this.showSearchOnExplore,
    required this.onSplashMode,
    required this.onSearchExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Branding', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: splashMode,
          decoration: const InputDecoration(labelText: 'Splash mode'),
          items: const [
            DropdownMenuItem(value: "auto", child: Text("Auto")),
            DropdownMenuItem(value: "light", child: Text("Light")),
            DropdownMenuItem(value: "dark", child: Text("Dark")),
          ],
          onChanged: (v) => onSplashMode(v ?? "auto"),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show search on Explore'),
          value: showSearchOnExplore,
          onChanged: onSearchExplore,
        ),
      ],
    );
  }
}

class _FeaturesPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _FeaturesPicker({required this.selected, required this.onChanged});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enabled Features', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final f in all)
              FilterChip(
                label: Text(f),
                selected: selected.contains(f),
                selectedColor: cs.primaryContainer,
                onSelected: (ok) {
                  final next = {...selected};
                  ok ? next.add(f) : next.remove(f);
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _NavEditor extends StatelessWidget {
  final List<NavItemDraft> navItems;
  final ValueChanged<List<NavItemDraft>> onChanged;

  const _NavEditor({required this.navItems, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = navItems.where((e) => e.enabled).toList();
    final disabled = navItems.where((e) => !e.enabled).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Navigation', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text('Toggle tabs + reorder (drag).',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
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
            return ListTile(
              key: ValueKey(item.id),
              title: Text(item.label),
              subtitle: Text(item.id),
              trailing: const Icon(Icons.drag_handle_rounded),
              leading: Checkbox(
                value: item.enabled,
                onChanged: (v) {
                  final next = navItems
                      .map((x) =>
                          x.id == item.id ? x.copyWith(enabled: v ?? true) : x)
                      .toList();
                  onChanged(next);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ...disabled.map(
          (item) => ListTile(
            title: Text(item.label),
            subtitle: Text(item.id),
            leading: Checkbox(
              value: item.enabled,
              onChanged: (v) {
                final next = navItems
                    .map((x) =>
                        x.id == item.id ? x.copyWith(enabled: v ?? false) : x)
                    .toList();
                onChanged(next);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeEditor extends StatelessWidget {
  final List<HomeSectionDraft> sections;
  final ValueChanged<List<HomeSectionDraft>> onChanged;

  const _HomeEditor({required this.sections, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = sections.where((s) => s.enabled).toList();
    final disabled = sections.where((s) => !s.enabled).toList();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Home Sections',
                style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            _TinyHintChip(text: 'Drag'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enable / reorder sections and edit limits.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(.65),
              ),
        ),
        const SizedBox(height: 12),
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
            final s = enabled[i];
            return Padding(
              key: ValueKey(s.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: _HomeSectionRow(
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
            );
          },
        ),
        if (disabled.isNotEmpty) ...[
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Disabled sections (${disabled.length})',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              children: [
                const SizedBox(height: 6),
                ...disabled.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HomeSectionRow(
                      section: s,
                      onToggle: (v) {
                        onChanged(sections
                            .map((x) =>
                                x.id == s.id ? x.copyWith(enabled: v) : x)
                            .toList());
                      },
                      onLimitTap: () async {
                        final next = await _pickLimit(context, s.limit);
                        if (next != null) {
                          onChanged(sections
                              .map((x) =>
                                  x.id == s.id ? x.copyWith(limit: next) : x)
                              .toList());
                        }
                      },
                    ),
                  ),
                ),
              ],
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

class _HomeSectionRow extends StatelessWidget {
  final HomeSectionDraft section;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLimitTap;

  const _HomeSectionRow({
    super.key,
    required this.section,
    required this.onToggle,
    required this.onLimitTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final icon = _iconFor(section.type);
    final title = _prettyType(section.type);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),

          // main text area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),

                // ✅ Wrap pills so no overflow
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(
                      text: section.layout,
                      bg: cs.surfaceContainerHighest,
                      fg: cs.onSurfaceVariant,
                    ),
                    if (section.feature != null)
                      _Pill(
                        text: section.feature!,
                        bg: cs.primaryContainer,
                        fg: cs.onPrimaryContainer,
                      ),
                    _Pill(
                      text: 'id: ${section.id}',
                      bg: cs.surfaceContainerHighest,
                      fg: cs.onSurface.withOpacity(.75),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ✅ fixed width controls column (prevents RenderFlex overflow)
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onLimitTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Text(
                      'Limit ${section.limit}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ FittedBox so Switch+Icon never overflow
                FittedBox(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: section.enabled,
                        onChanged: onToggle,
                      ),
                      const Icon(Icons.drag_handle_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
        return 'Items List';
      case 'BANNER':
        return 'Hero Banner';
      default:
        final s = t.toLowerCase().replaceAll('_', ' ');
        return s.isEmpty ? type : '${s[0].toUpperCase()}${s.substring(1)}';
    }
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TinyHintChip extends StatelessWidget {
  final String text;
  const _TinyHintChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.7),
            ),
      ),
    );
  }
}

class _GeneratedPreview extends StatelessWidget {
  final RuntimeJsonOut out;
  final Color borderColor;

  const _GeneratedPreview({required this.out, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Generated JSON (debug only)'),
      children: [
        _JsonBox(
            title: 'navJson', value: out.navJson, borderColor: borderColor),
        _JsonBox(
            title: 'homeJson', value: out.homeJson, borderColor: borderColor),
        _JsonBox(
            title: 'enabledFeaturesJson',
            value: out.enabledFeaturesJson,
            borderColor: borderColor),
        _JsonBox(
            title: 'brandingJson',
            value: out.brandingJson,
            borderColor: borderColor),
      ],
    );
  }
}

class _JsonBox extends StatelessWidget {
  final String title;
  final String value;
  final Color borderColor;

  const _JsonBox({
    required this.title,
    required this.value,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}
