import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/managed_payment_type.dart';

class PaymentTypeCard extends StatelessWidget {
  final ManagedPaymentType type;
  final bool isToggling;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const PaymentTypeCard({
    super.key,
    required this.type,
    required this.isToggling,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateStr = type.createdAt != null
        ? DateFormat('MMM d, yyyy').format(type.createdAt!)
        : '—';

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
              backgroundColor: cs.tertiaryContainer,
              child: Icon(Icons.category_rounded, size: 20, color: cs.onTertiaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.typeName,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _CodeChip(code: type.code),
                  if (type.description.isNotEmpty) ...[const SizedBox(height: 4), Text(type.description, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis)],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        type.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 14,
                        color: type.isActive ? cs.primary : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type.isActive ? 'Active' : 'Inactive',
                        style: tt.labelSmall?.copyWith(color: type.isActive ? cs.primary : cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Text('Created $dateStr', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
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
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : Switch.adaptive(value: type.isActive, onChanged: onToggle),
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

class _CodeChip extends StatelessWidget {
  final String code;
  const _CodeChip({required this.code});

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
        code,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}
