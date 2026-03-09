import 'package:flutter/material.dart';

class OwnerPillNavItem {
  final Widget icon;
  final String label;
  final int badgeCount;

  const OwnerPillNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });
}

class OwnerPillNavBar extends StatelessWidget {
  final List<OwnerPillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const OwnerPillNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final safeIndex =
        items.isEmpty ? 0 : currentIndex.clamp(0, items.length - 1);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == safeIndex;
            final item = items[i];

            return Expanded(
              child: _PillItem(
                label: item.label,
                icon: item.icon,
                badgeCount: item.badgeCount,
                selected: selected,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  final String label;
  final Widget icon;
  final int badgeCount;
  final bool selected;
  final VoidCallback onTap;

  const _PillItem({
    required this.label,
    required this.icon,
    required this.badgeCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(.14) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? cs.primary.withOpacity(.35)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? cs.primary.withOpacity(.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: IconTheme(
                    data: IconThemeData(
                      size: 22,
                      color: selected
                          ? cs.primary
                          : cs.onSurface.withOpacity(.65),
                    ),
                    child: icon,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: cs.surface,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onError,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tt.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withOpacity(.65),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 3,
              width: selected ? 18 : 0,
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}