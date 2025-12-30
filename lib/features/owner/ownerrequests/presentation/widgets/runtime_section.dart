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

        // Debug JSON (optional): keep or remove as you want
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Generated JSON (debug only)'),
          children: [
            _JsonBox(
              title: 'brandingJson',
              value: draft.toJsonOut().brandingJson,
              borderColor: cs.outlineVariant,
            ),
            _JsonBox(
              title: 'enabledFeaturesJson',
              value: draft.toJsonOut().enabledFeaturesJson,
              borderColor: cs.outlineVariant,
            ),
            _JsonBox(
              title: 'navJson',
              value: draft.toJsonOut().navJson,
              borderColor: cs.outlineVariant,
            ),
            _JsonBox(
              title: 'homeJson',
              value: draft.toJsonOut().homeJson,
              borderColor: cs.outlineVariant,
            ),
          ],
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
            ButtonSegment(value: MenuType.hamburger, label: Text('Hamburger')),
          ],
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
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
                label: Text(
                  f,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected.contains(f)
                        ? cs.onPrimary
                        : cs.onSurface,
                  ),
                ),
                selected: selected.contains(f),

                // ✅ Selected color = submit button color (primary)
                selectedColor: cs.primary,

                // ✅ Unselected color: NOT white
                backgroundColor: cs.surfaceContainerHighest,
                surfaceTintColor: cs.surfaceContainerHighest,

                shape: StadiumBorder(
                  side: BorderSide(
                    color: selected.contains(f) ? cs.primary : cs.outlineVariant,
                  ),
                ),
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
        const SizedBox(height: 6),
        Text(
          'Check/uncheck to show/hide in preview menu. Drag enabled items to reorder.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),

        // Enabled (reorderable)
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: enabled.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex -= 1;

            final enabledList = [...enabled];
            final item = enabledList.removeAt(oldIndex);
            enabledList.insert(newIndex, item);

            // keep disabled at end
            onChanged([...enabledList, ...disabled]);
          },
          itemBuilder: (ctx, i) {
            final item = enabled[i];
            return _NavRow(
              key: ValueKey(item.id),
              item: item,
              onToggle: (v) {
                final next = navItems
                    .map((x) => x.id == item.id ? x.copyWith(enabled: v) : x)
                    .toList();
                onChanged(next);
              },
            );
          },
        ),

        if (disabled.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Disabled (${disabled.length})',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          for (final item in disabled)
            _NavRow(
              key: ValueKey('d_${item.id}'),
              item: item,
              showDrag: false,
              onToggle: (v) {
                final next = navItems
                    .map((x) => x.id == item.id ? x.copyWith(enabled: v) : x)
                    .toList();
                onChanged(next);
              },
            ),
        ],
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  final NavItemDraft item;
  final bool showDrag;
  final ValueChanged<bool> onToggle;

  const _NavRow({
    super.key,
    required this.item,
    required this.onToggle,
    this.showDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.enabled,
            onChanged: (v) => onToggle(v ?? false),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                _MiniTag(text: item.id), // ✅ no "=" anywhere
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (showDrag) const Icon(Icons.drag_handle_rounded),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});

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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: cs.onSurface.withOpacity(.8),
        ),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Home Sections', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          'Check/uncheck to show/hide in preview. Drag enabled items to reorder.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),

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
          Text(
            'Disabled (${disabled.length})',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          for (final s in disabled)
            _HomeRow(
              key: ValueKey('d_${s.id}'),
              section: s,
              showDrag: false,
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
  final bool showDrag;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLimitTap;

  const _HomeRow({
    super.key,
    required this.section,
    required this.onToggle,
    required this.onLimitTap,
    this.showDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = _prettyType(section.type);

    // ✅ One line summary, no id, no "full", no "="
    final parts = <String>[
      title,
      section.layout,
      'Limit ${section.limit}',
      if (section.feature != null) section.feature!,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
          ),
          Expanded(
            child: InkWell(
              onTap: onLimitTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  parts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (showDrag) const Icon(Icons.drag_handle_rounded),
        ],
      ),
    );
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
