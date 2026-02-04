// lib/features/owner/ownerhome/presentation/widgets/request_card.dart
import 'package:flutter/material.dart';
import '../../../common/domain/entities/app_request.dart';

class RequestCard extends StatelessWidget {
  final AppRequest req;
  const RequestCard({super.key, required this.req});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final (bg, fg, label) = switch (req.status) {
      'DELIVERED' => (cs.secondary.withOpacity(.14), cs.secondary, 'Delivered'),
      'IN_PRODUCTION' => (
          cs.tertiaryContainer.withOpacity(.30),
          cs.tertiary,
          'In production'
        ),
      'APPROVED' => (cs.primary.withOpacity(.12), cs.primary, 'Approved'),
      'PENDING' => (
          cs.outlineVariant.withOpacity(.24),
          cs.onSurface,
          'Pending'
        ),
      'REJECTED' => (cs.errorContainer.withOpacity(.28), cs.error, 'Rejected'),
      _ => (cs.surfaceContainerHighest.withOpacity(.22), cs.onSurface, req.status),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top line: name + status chip
          Row(
            children: [
              Expanded(
                child: Text(
                  req.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(label,
                    style: tt.labelSmall
                        ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Second line: project • status
          Text(
            '${req.projectName ?? '—'} • ${req.status}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7)),
          ),

          const SizedBox(height: 6),

          // Meta row like the mock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _ago(req.createdAt),
                style: tt.labelSmall
                    ?.copyWith(color: cs.onSurface.withOpacity(.55)),
              ),
              if ((req.apkUrl ?? '').isNotEmpty)
                Text('APK download →',
                    style: tt.labelSmall?.copyWith(
                        color: cs.secondary, fontWeight: FontWeight.w600))
              else
                Text('Delivery ETA · 2d',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurface.withOpacity(.55))),
            ],
          ),
        ],
      ),
    );
  }

  String _ago(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff <= 0) return 'Requested today';
    if (diff == 1) return 'Requested 1d ago';
    return 'Requested ${diff}d ago';
  }
}
