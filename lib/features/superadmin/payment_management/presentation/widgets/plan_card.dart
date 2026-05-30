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
              isSmall ? 12 : 8,
              12,
            ),
            child: isSmall
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MainContent(
                        plan: plan,
                        usersText: usersText,
                        cs: cs,
                        tt: tt,
                        compact: true,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _Actions(
                          isDeleting: isDeleting,
                          onEdit: onEdit,
                          onDelete: () => _confirmDelete(context),
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
                          plan: plan,
                          usersText: usersText,
                          cs: cs,
                          tt: tt,
                          compact: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Actions(
                        isDeleting: isDeleting,
                        onEdit: onEdit,
                        onDelete: () => _confirmDelete(context),
                        horizontal: false,
                      ),
                    ],
                  ),
          ),
        );
      },
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

    if (confirmed == true) {
      onDelete();
    }
  }
}

class _MainContent extends StatelessWidget {
  final Plan plan;
  final String usersText;
  final ColorScheme cs;
  final TextTheme tt;
  final bool compact;

  const _MainContent({
    required this.plan,
    required this.usersText,
    required this.cs,
    required this.tt,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: compact ? 19 : 22,
          backgroundColor: cs.primaryContainer,
          child: Icon(
            Icons.layers_rounded,
            size: compact ? 18 : 20,
            color: cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.displayName,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              _CodeChip(code: plan.code),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
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
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool horizontal;

  const _Actions({
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
    required this.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final children = [
      IconButton(
        icon: const Icon(Icons.edit_outlined, size: 20),
        tooltip: 'Edit',
        visualDensity: VisualDensity.compact,
        onPressed: isDeleting ? null : onEdit,
      ),
      if (isDeleting)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            color: cs.error,
          ),
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
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

class _CodeChip extends StatelessWidget {
  final String code;

  const _CodeChip({
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimaryContainer,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}