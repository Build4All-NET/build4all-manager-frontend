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
                        type: type,
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
                          isActive: type.isActive,
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
                          type: type,
                          dateStr: dateStr,
                          cs: cs,
                          tt: tt,
                          compact: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Actions(
                        isToggling: isToggling,
                        isActive: type.isActive,
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
  final ManagedPaymentType type;
  final String dateStr;
  final ColorScheme cs;
  final TextTheme tt;
  final bool compact;

  const _MainContent({
    required this.type,
    required this.dateStr,
    required this.cs,
    required this.tt,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = type.isActive ? cs.primary : cs.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: compact ? 19 : 22,
          backgroundColor: cs.tertiaryContainer,
          child: Icon(
            Icons.category_rounded,
            size: compact ? 18 : 20,
            color: cs.onTertiaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.typeName,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              _CodeChip(code: type.code),
              if (type.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  type.description,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _TinyInfo(
                    icon: type.isActive
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    label: type.isActive ? 'Active' : 'Inactive',
                    color: statusColor,
                  ),
                  _TinyInfo(
                    icon: Icons.calendar_month_rounded,
                    label: 'Created $dateStr',
                    color: cs.onSurfaceVariant,
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
  final bool isToggling;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final bool horizontal;

  const _Actions({
    required this.isToggling,
    required this.isActive,
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
            value: isActive,
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
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        code,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontFamily: 'monospace',
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