import 'package:flutter/material.dart';

class PublishStatusChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String Function(String status) labelOf;

  const PublishStatusChips({
    super.key,
    required this.value,
    required this.onChanged,
    required this.labelOf,
  });

  static const statuses = [
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: statuses.map((s) {
          final selected = s == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labelOf(s)),
              selected: selected,
              onSelected: (_) => onChanged(s),
              selectedColor: cs.primary.withOpacity(.14),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? cs.primary : cs.onSurface,
              ),
              side: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
