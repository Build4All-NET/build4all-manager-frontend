import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';
import '../../../publish_admin/domain/entities/app_publish_request_admin.dart';

class PublishRequestCard extends StatelessWidget {
  final AppPublishRequestAdmin item;
  final VoidCallback onTap;

  const PublishRequestCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<UiTokens>();

    final badge = _badgeColor(cs, item.status);

    return InkWell(
      borderRadius: BorderRadius.circular(tokens?.radiusLg ?? 18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(tokens?.radiusLg ?? 18),
          border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
          boxShadow: tokens?.cardShadow ??
              const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 14,
                  offset: Offset(0, 10),
                ),
              ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
              ),
              child: Icon(Icons.upload_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),

            // Main
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.appName ?? 'App',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(context, '${item.platform} • ${item.store}'),
                      _chip(context, 'AUP ${item.aupId ?? "-"}'),
                      _statusChip(context, item.status, badge),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String text, Color c) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
      ),
    );
  }

  Color _badgeColor(ColorScheme cs, String status) {
    final s = status.toUpperCase();
    if (s == 'SUBMITTED') return cs.primary;
    if (s == 'APPROVED') return Colors.green;
    if (s == 'REJECTED') return Colors.red;
    if (s == 'PUBLISHED') return Colors.teal;
    return cs.secondary;
  }
}
