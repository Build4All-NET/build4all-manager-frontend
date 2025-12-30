import 'package:flutter/material.dart';
import 'runtime_draft.dart';

/// ===============================================================
/// RuntimeSection (Figma-style)
///
/// ✅ Purpose:
/// - Displays the "Runtime Config" settings inside Create App Request.
/// - Keeps UI consistent with your other panels (Basics / Branding / Palette).
///
/// ✅ Update:
/// - Menu Type options:
///   - Bottom Navigation
///   - Hamburger menu   (instead of Drawer)
///
/// ✅ Preview behavior:
/// - If Hamburger menu => preview shows hamburger icon + hides bottom navigation
/// - If Bottom Navigation => preview shows bottom navigation
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
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title (like Figma)
        Text(
          'Runtime Config',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(
          'Configure how the app navigation behaves in runtime.',
          style: t.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(.65),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Card container
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(
                title: 'Navigation',
                subtitle: 'Choose the navigation style shown in the app.',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 12),

              // Menu Type tile (clickable look)
              _ClickableField(
                title: 'Menu Type',
                value: draft.menuType.uiLabel,
                icon: draft.menuType == MenuType.hamburger
                    ? Icons.menu_rounded
                    : Icons.view_agenda_rounded,
                onTap: () async {
                  final picked = await _pickMenuType(context, draft.menuType);
                  if (picked != null) onChanged(draft.copyWith(menuType: picked));
                },
              ),

              const SizedBox(height: 10),

              // Helper note (Figma info text)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        draft.menuType == MenuType.hamburger
                            ? 'Preview will display a hamburger icon in the header and hide bottom navigation.'
                            : 'Preview will display bottom navigation tabs.',
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ===============================================================
  /// Bottom sheet picker for menu type (Figma-ish)
  /// ===============================================================
  static Future<MenuType?> _pickMenuType(
    BuildContext context,
    MenuType current,
  ) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return showModalBottomSheet<MenuType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Menu Type',
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Icon(Icons.menu_open_rounded, color: cs.primary),
                  ],
                ),
                const SizedBox(height: 10),

                _OptionTile(
                  selected: current == MenuType.bottom,
                  title: 'Bottom Navigation',
                  subtitle: 'Show tabs at the bottom (Home, Explore, Cart, Profile).',
                  leading: Icons.view_agenda_rounded,
                  onTap: () => Navigator.pop(ctx, MenuType.bottom),
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  selected: current == MenuType.hamburger,
                  title: 'Hamburger menu',
                  subtitle: 'Show menu icon in header and hide bottom tabs.',
                  leading: Icons.menu_rounded,
                  onTap: () => Navigator.pop(ctx, MenuType.hamburger),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ===============================================================
/// Small UI helpers (same visual language as your screen)
/// ===============================================================
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeaderRow({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: t.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClickableField extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _ClickableField({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.70),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData leading;
  final VoidCallback onTap;

  const _OptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(leading, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: t.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
