import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/license_plan_pricing.dart';
import '../bloc/license_plan_pricing_bloc.dart';
import '../bloc/license_plan_pricing_event.dart';

class LicensePlanPricingCard extends StatelessWidget {
  final LicensePlanPricing pricing;
  final bool isToggling;
  final bool isDeleting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const LicensePlanPricingCard({
    super.key,
    required this.pricing,
    required this.isToggling,
    this.isDeleting = false,
    required this.onToggle,
    required this.onEdit,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pricing Row'),
        content: Text(
          'Are you sure you want to delete the pricing for '
          '"${pricing.planCode}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context
          .read<LicensePlanPricingBloc>()
          .add(RemoveLicensePlanPricing(pricing.id));
    }
  }

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

    final priceText = '${_fmtAmount(pricing.price)} ${pricing.currency}';

    final hasDiscount = pricing.hasDiscount;

    final discountText = hasDiscount
        ? '${_fmtAmount(pricing.discountedPrice!)} ${pricing.currency}'
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool isVerySmall = width < 360;
        final bool isSmall = width < 520;

        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isVerySmall ? 10 : 16,
              12,
              isVerySmall ? 8 : 12,
              12,
            ),
            child: isSmall
                ? _CompactPricingLayout(
                    pricing: pricing,
                    priceText: priceText,
                    discountText: discountText,
                    hasDiscount: hasDiscount,
                    dateStr: dateStr,
                    isToggling: isToggling,
                    isDeleting: isDeleting,
                    onToggle: onToggle,
                    onEdit: onEdit,
                    onDelete: () => _confirmDelete(context),
                    cs: cs,
                    tt: tt,
                  )
                : _WidePricingLayout(
                    pricing: pricing,
                    priceText: priceText,
                    discountText: discountText,
                    hasDiscount: hasDiscount,
                    dateStr: dateStr,
                    isToggling: isToggling,
                    isDeleting: isDeleting,
                    onToggle: onToggle,
                    onEdit: onEdit,
                    onDelete: () => _confirmDelete(context),
                    cs: cs,
                    tt: tt,
                  ),
          ),
        );
      },
    );
  }
}

class _WidePricingLayout extends StatelessWidget {
  final LicensePlanPricing pricing;
  final String priceText;
  final String? discountText;
  final bool hasDiscount;
  final String dateStr;
  final bool isToggling;
  final bool isDeleting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ColorScheme cs;
  final TextTheme tt;

  const _WidePricingLayout({
    required this.pricing,
    required this.priceText,
    required this.discountText,
    required this.hasDiscount,
    required this.dateStr,
    required this.isToggling,
    required this.isDeleting,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: cs.secondaryContainer,
          child: Icon(
            Icons.sell_rounded,
            size: 20,
            color: cs.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PricingMainInfo(
            pricing: pricing,
            priceText: priceText,
            discountText: discountText,
            hasDiscount: hasDiscount,
            dateStr: dateStr,
            cs: cs,
            tt: tt,
          ),
        ),
        const SizedBox(width: 8),
        _PricingActions(
          pricing: pricing,
          isToggling: isToggling,
          isDeleting: isDeleting,
          onToggle: onToggle,
          onEdit: onEdit,
          onDelete: onDelete,
          vertical: true,
        ),
      ],
    );
  }
}

class _CompactPricingLayout extends StatelessWidget {
  final LicensePlanPricing pricing;
  final String priceText;
  final String? discountText;
  final bool hasDiscount;
  final String dateStr;
  final bool isToggling;
  final bool isDeleting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ColorScheme cs;
  final TextTheme tt;

  const _CompactPricingLayout({
    required this.pricing,
    required this.priceText,
    required this.discountText,
    required this.hasDiscount,
    required this.dateStr,
    required this.isToggling,
    required this.isDeleting,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.secondaryContainer,
              child: Icon(
                Icons.sell_rounded,
                size: 18,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PricingMainInfo(
                pricing: pricing,
                priceText: priceText,
                discountText: discountText,
                hasDiscount: hasDiscount,
                dateStr: dateStr,
                cs: cs,
                tt: tt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: _PricingActions(
            pricing: pricing,
            isToggling: isToggling,
            isDeleting: isDeleting,
            onToggle: onToggle,
            onEdit: onEdit,
            onDelete: onDelete,
            vertical: false,
          ),
        ),
      ],
    );
  }
}

class _PricingMainInfo extends StatelessWidget {
  final LicensePlanPricing pricing;
  final String priceText;
  final String? discountText;
  final bool hasDiscount;
  final String dateStr;
  final ColorScheme cs;
  final TextTheme tt;

  const _PricingMainInfo({
    required this.pricing,
    required this.priceText,
    required this.discountText,
    required this.hasDiscount,
    required this.dateStr,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final discountLabel = pricing.discountLabel ??
        (pricing.discountPercent != null
            ? 'Save ${pricing.discountPercent}%'
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                pricing.planCode,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _CycleChip(billingCycle: pricing.billingCycle),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              discountText ?? priceText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
            if (hasDiscount)
              Text(
                priceText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (hasDiscount && discountLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            discountLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.labelSmall?.copyWith(
              color: cs.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Important:
        // This replaces the old Row that caused the overflow.
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusChip(
              isActive: pricing.isActive,
              cs: cs,
              tt: tt,
            ),
            _CreatedChip(
              dateStr: dateStr,
              cs: cs,
              tt: tt,
            ),
          ],
        ),
      ],
    );
  }
}

class _PricingActions extends StatelessWidget {
  final LicensePlanPricing pricing;
  final bool isToggling;
  final bool isDeleting;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool vertical;

  const _PricingActions({
    required this.pricing,
    required this.isToggling,
    required this.isDeleting,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (isToggling)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        Transform.scale(
          scale: 0.86,
          child: Switch.adaptive(
            value: pricing.isActive,
            onChanged: onToggle,
          ),
        ),
      IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        tooltip: 'Edit',
        visualDensity: VisualDensity.compact,
        onPressed: isDeleting ? null : onEdit,
      ),
      if (isDeleting)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
        ),
    ];

    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  final ColorScheme cs;
  final TextTheme tt;

  const _StatusChip({
    required this.isActive,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? cs.primary : cs.onSurfaceVariant;

    return _TinyChip(
      icon: isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
      label: isActive ? 'Active' : 'Inactive',
      color: color,
      cs: cs,
      tt: tt,
    );
  }
}

class _CreatedChip extends StatelessWidget {
  final String dateStr;
  final ColorScheme cs;
  final TextTheme tt;

  const _CreatedChip({
    required this.dateStr,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return _TinyChip(
      icon: Icons.calendar_month_rounded,
      label: 'Created $dateStr',
      color: cs.onSurfaceVariant,
      cs: cs,
      tt: tt,
    );
  }
}

class _TinyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ColorScheme cs;
  final TextTheme tt;

  const _TinyChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: tt.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleChip extends StatelessWidget {
  final PricingBillingCycle billingCycle;

  const _CycleChip({
    required this.billingCycle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        billingCycle.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}