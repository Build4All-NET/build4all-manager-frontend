import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/payment_method.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final bool isToggling;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.isToggling,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final dateStr = method.createdAt != null
        ? DateFormat('MMM d, yyyy').format(method.createdAt!)
        : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 430;

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isSmall ? 12 : 16,
              12,
              isSmall ? 12 : 10,
              12,
            ),
            child: isSmall
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MainContent(
                        method: method,
                        dateStr: dateStr,
                        cs: cs,
                        tt: tt,
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _Actions(
                          isToggling: isToggling,
                          isEnabled: method.isEnabled,
                          onToggle: onToggle,
                          onEdit: onEdit,
                          horizontal: true,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MainContent(
                          method: method,
                          dateStr: dateStr,
                          cs: cs,
                          tt: tt,
                          compact: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Actions(
                        isToggling: isToggling,
                        isEnabled: method.isEnabled,
                        onToggle: onToggle,
                        onEdit: onEdit,
                        horizontal: false,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _MainContent extends StatelessWidget {
  final PaymentMethod method;
  final String dateStr;
  final ColorScheme cs;
  final TextTheme tt;
  final bool compact;

  const _MainContent({
    required this.method,
    required this.dateStr,
    required this.cs,
    required this.tt,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TypeAvatar(code: method.paymentType.code, compact: compact),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method.paymentDisplayName,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(label: method.paymentType.displayName),
                  if (method.providerCode.isNotEmpty)
                    _Chip(label: method.providerCode),
                ],
              ),
              if (method.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  method.description,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 7),
              _TinyInfo(
                icon: Icons.calendar_month_rounded,
                label: 'Created $dateStr',
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final bool isToggling;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final bool horizontal;

  const _Actions({
    required this.isToggling,
    required this.isEnabled,
    required this.onToggle,
    required this.onEdit,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      if (isToggling)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        Transform.scale(
          scale: 0.86,
          child: Switch.adaptive(
            value: isEnabled,
            onChanged: onToggle,
          ),
        ),
      IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        tooltip: 'Edit',
        visualDensity: VisualDensity.compact,
        onPressed: onEdit,
      ),
    ];

    if (horizontal) {
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

class _TypeAvatar extends StatelessWidget {
  final String code;
  final bool compact;

  const _TypeAvatar({
    required this.code,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: compact ? 19 : 22,
      backgroundColor: cs.primaryContainer,
      child: Icon(
        _icon(code),
        size: compact ? 18 : 20,
        color: cs.onPrimaryContainer,
      ),
    );
  }

  IconData _icon(String code) => switch (code.toUpperCase()) {
        'CASH' => Icons.money_rounded,
        'PAYPAL' => Icons.account_balance_wallet_rounded,
        'STRIPE' => Icons.credit_card_rounded,
        'VISA' => Icons.credit_score_rounded,
        'BANK_TRANSFER' => Icons.account_balance_rounded,
        _ => Icons.payment_rounded,
      };
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TinyInfo({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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