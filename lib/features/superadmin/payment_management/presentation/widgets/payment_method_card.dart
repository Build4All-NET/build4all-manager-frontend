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

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeAvatar(code: method.paymentType.code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.paymentDisplayName,
                    style:
                        tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _Chip(label: method.paymentType.displayName),
                      if (method.providerCode.isNotEmpty)
                        _Chip(label: method.providerCode),
                    ],
                  ),
                  if (method.description.isNotEmpty) ...[const SizedBox(height: 4), Text(method.description, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis)],
                  const SizedBox(height: 6),
                  Text('Created $dateStr', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
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
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Switch.adaptive(value: method.isEnabled, onChanged: onToggle),
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

class _TypeAvatar extends StatelessWidget {
  final String code;
  const _TypeAvatar({required this.code});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 22,
      backgroundColor: cs.primaryContainer,
      child: Icon(_icon(code), size: 20, color: cs.onPrimaryContainer),
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
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSecondaryContainer),
      ),
    );
  }
}
