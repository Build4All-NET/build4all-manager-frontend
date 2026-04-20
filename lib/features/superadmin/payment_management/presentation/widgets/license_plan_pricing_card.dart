import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/license_plan_pricing.dart';

class LicensePlanPricingCard extends StatelessWidget {
  final LicensePlanPricing pricing;
  final bool isToggling;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const LicensePlanPricingCard({
    super.key,
    required this.pricing,
    required this.isToggling,
    required this.onToggle,
    required this.onEdit,
  });

  String _fmtAmount(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateStr = pricing.createdAt != null
        ? DateFormat('MMM d, yyyy').format(pricing.createdAt!)
        : '—';

    final priceText =
        '${_fmtAmount(pricing.price)} ${pricing.currency}';
    final hasDiscount = pricing.hasDiscount;
    final discountText = hasDiscount
        ? '${_fmtAmount(pricing.discountedPrice!)} ${pricing.currency}'
        : null;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.secondaryContainer,
              child: Icon(Icons.sell_rounded,
                  size: 20, color: cs.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pricing.planCode,
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _CycleChip(billingCycle: pricing.billingCycle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        discountText ?? priceText,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          priceText,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasDiscount &&
                      (pricing.discountLabel != null ||
                          pricing.discountPercent != null)) ...[
                    const SizedBox(height: 4),
                    Text(
                      pricing.discountLabel ??
                          'Save ${pricing.discountPercent}%',
                      style: tt.labelSmall?.copyWith(
                        color: cs.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        pricing.isActive
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 14,
                        color: pricing.isActive
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pricing.isActive ? 'Active' : 'Inactive',
                        style: tt.labelSmall?.copyWith(
                            color: pricing.isActive
                                ? cs.primary
                                : cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Text('Created $dateStr',
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isToggling
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Switch.adaptive(
                        value: pricing.isActive, onChanged: onToggle),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleChip extends StatelessWidget {
  final PricingBillingCycle billingCycle;
  const _CycleChip({required this.billingCycle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        billingCycle.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
