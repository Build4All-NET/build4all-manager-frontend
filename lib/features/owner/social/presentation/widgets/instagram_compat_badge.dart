import 'package:flutter/material.dart';

import '../../data/services/instagram_compat.dart';

/// Small chip the product editor renders next to the chosen image,
/// telling the OWNER whether the image will publish to Instagram and,
/// if not, the specific reason.
///
/// The verdict is computed locally (see [InstagramCompat.check]) so the
/// chip updates immediately when the user swaps the image — no server
/// round-trip.
class InstagramCompatBadge extends StatelessWidget {
  final InstagramCompatVerdict verdict;
  const InstagramCompatBadge({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (verdict.accepted) {
      return Tooltip(
        message: '${verdict.width} × ${verdict.height} — '
            'aspect ${verdict.aspectRatio.toStringAsFixed(2)}:1',
        child: Chip(
          avatar: Icon(Icons.check_circle, color: scheme.primary, size: 16),
          label: const Text('OK for Instagram'),
          labelStyle: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
          visualDensity: VisualDensity.compact,
          backgroundColor: scheme.primary.withOpacity(0.10),
          side: BorderSide(color: scheme.primary.withOpacity(0.25)),
        ),
      );
    }

    final reason = verdict.rejectedReason!;
    return Tooltip(
      message: reason.explanation,
      child: ActionChip(
        avatar: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 16),
        label: Text(reason.label),
        labelStyle: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
        visualDensity: VisualDensity.compact,
        backgroundColor: scheme.error.withOpacity(0.08),
        side: BorderSide(color: scheme.error.withOpacity(0.25)),
        onPressed: () => _showExplanation(context, reason),
      ),
    );
  }

  void _showExplanation(BuildContext context, InstagramRejectionReason reason) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(reason.label,
                  style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            Text(reason.explanation,
                style: Theme.of(context).textTheme.bodyMedium),
            if (verdict.detail != null) ...[
              const SizedBox(height: 8),
              Text(verdict.detail!,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
