import 'package:flutter/material.dart';

class PublishStatusFilterButton extends StatelessWidget {
  final String value;
  final String Function(String status) labelOf;
  final ValueChanged<String> onChanged;

  const PublishStatusFilterButton({
    super.key,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });

  static const statuses = [
    'ALL',
    'SUBMITTED',
    'IN_REVIEW',
    'APPROVED',
    'REJECTED',
    'PUBLISHED',
    'DRAFT',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'All Status',
      onSelected: (s) {
        // map ALL -> SUBMITTED? or keep ALL if backend supports
        if (s == 'ALL') {
          onChanged('SUBMITTED'); // simplest behavior with your backend
          return;
        }
        onChanged(s);
      },
      itemBuilder: (_) => statuses
          .map(
            (s) => PopupMenuItem(
              value: s,
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: cs.onSurface.withOpacity(.75),
                  ),
                  const SizedBox(width: 10),
                  Text(labelOf(s)),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined,
                color: cs.onSurface.withOpacity(.8), size: 18),
            const SizedBox(width: 10),
            Text(
              'All Status',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
