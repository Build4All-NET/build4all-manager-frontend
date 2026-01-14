import 'package:flutter/material.dart';
import '../../domain/entities/app_publish_request_admin.dart';

class RequestedAppRow extends StatelessWidget {
  final AppPublishRequestAdmin item;
  final bool showVersion;
  final bool showRequested;
  final VoidCallback onViewPublish;

  const RequestedAppRow({
    super.key,
    required this.item,
    required this.showVersion,
    required this.showRequested,
    required this.onViewPublish,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final w = c.maxWidth;

        // 🔥 Breakpoints — tweak if you want
        final compact = w < 700; // phones / small tablets
        final tiny = w < 420; // very small phones

        if (compact) {
          return _compactRow(context, tiny: tiny);
        }

        return _tableRow(context);
      },
    );
  }

  // =========================
  // ✅ COMPACT (NO OVERFLOW)
  // =========================
  Widget _compactRow(BuildContext context, {required bool tiny}) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: App
          Row(
            children: [
              _AppIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.appName ?? 'App',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'AUP ${item.aupId ?? "-"} • ${item.store}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(.65),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _MoreMenu(item: item),
            ],
          ),

          const SizedBox(height: 10),

          // Middle: platforms + status (wrap)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PlatformBadge.android(ready: true),
              _PlatformBadge.ios(ready: true),
              _StatusPill(status: item.status),
            ],
          ),

          const SizedBox(height: 10),

          // Requested date / request id (optional)
          if (showRequested) ...[
            Text(
              _prettyDate(item.requestedAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'REQ-${item.id.toString().padLeft(6, "0")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.65),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
          ],

          // Bottom: action button full width (no overflow ever)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: onViewPublish,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View & Publish',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: tiny ? 13 : 14, // ✅ tiny screens shrink text
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // ✅ TABLE (WIDE SCREENS)
  // =========================
  Widget _tableRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 38,
            child: Row(
              children: [
                _AppIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.appName ?? 'App',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'AUP ${item.aupId ?? "-"} • ${item.store}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 22,
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _PlatformBadge.android(ready: true),
                _PlatformBadge.ios(ready: true),
              ],
            ),
          ),

          if (showVersion)
            Expanded(
              flex: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // keep placeholders
                  Text('Android: —'),
                  SizedBox(height: 6),
                  Text('iOS: —'),
                ],
              ),
            ),

          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(status: item.status),
            ),
          ),

          if (showRequested)
            Expanded(
              flex: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_prettyDate(item.requestedAt),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    'REQ-${item.id.toString().padLeft(6, "0")}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

          // ✅ IMPORTANT: Actions should be flexible, not fixed width
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: onViewPublish,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View & Publish',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _MoreMenu(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _prettyDate(DateTime? dt) {
    if (dt == null) return '—';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

// ======= same helpers you had (keep them) =======

class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Icon(Icons.inventory_2_rounded, color: cs.onSurfaceVariant),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ready;
  final Color tint;

  const _PlatformBadge._({
    required this.icon,
    required this.label,
    required this.ready,
    required this.tint,
  });

  factory _PlatformBadge.android({required bool ready}) => _PlatformBadge._(
        icon: Icons.android_rounded,
        label: ready ? 'Ready' : 'Pending',
        ready: ready,
        tint: Colors.green,
      );

  factory _PlatformBadge.ios({required bool ready}) => _PlatformBadge._(
        icon: Icons.apple,
        label: ready ? 'Ready' : 'Pending',
        ready: ready,
        tint: Colors.blue,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: tint.withOpacity(.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: tint),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (ready ? tint : cs.outlineVariant).withOpacity(.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ready ? tint : cs.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = status.toUpperCase();

    Color c;
    if (s == 'SUBMITTED' || s == 'IN_REVIEW')
      c = cs.primary;
    else if (s == 'APPROVED')
      c = Colors.green;
    else if (s == 'REJECTED')
      c = Colors.red;
    else if (s == 'PUBLISHED')
      c = Colors.teal;
    else
      c = cs.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final AppPublishRequestAdmin item;
  const _MoreMenu({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'More',
      onSelected: (_) {},
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'history', child: Text('CI/CD History (Coming soon)')),
        PopupMenuItem(value: 'logs', child: Text('View Logs (Coming soon)')),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surface,
          shape: BoxShape.circle,
          border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
        ),
        child: Icon(Icons.more_horiz_rounded, color: cs.onSurfaceVariant),
      ),
    );
  }
}
