import 'package:flutter/material.dart';

import '../../domain/entities/plan.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final usersText =
        plan.usersAllowed != null ? '${plan.usersAllowed} users' : 'Unlimited';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.layers_rounded,
                  size: 20, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.displayName,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _CodeChip(code: plan.code),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _InfoBadge(
                        icon: Icons.people_alt_outlined,
                        label: usersText,
                      ),
                      _InfoBadge(
                        icon: Icons.calendar_month_outlined,
                        label: '${plan.billingCycleMonths} mo',
                      ),
                      if (plan.requiresDedicatedServer)
                        _InfoBadge(
                          icon: Icons.dns_outlined,
                          label: 'Dedicated server',
                          color: cs.tertiary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit',
                  visualDensity: VisualDensity.compact,
                  onPressed: isDeleting ? null : onEdit,
                ),
                isDeleting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 20, color: cs.error),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _confirmDelete(context),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
          'Are you sure you want to delete the "${plan.displayName}" plan? '
          'This action cannot be undone.',
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
    if (confirmed == true) onDelete();
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
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: effectiveColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: effectiveColor),
        ),
      ],
    );
  }
}
