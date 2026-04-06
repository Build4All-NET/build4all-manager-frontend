import 'package:build4all_manager/l10n/app_localizations.dart';
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
        final compact = w < 700;
        final tiny = w < 420;

        if (compact) {
          return _compactRow(context, tiny: tiny);
        }

        return _tableRow(context);
      },
    );
  }

  Widget _compactRow(BuildContext context, {required bool tiny}) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _AppIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.appName?.trim().isNotEmpty == true
                          ? item.appName!
                          : l10n.publish_unknown_app,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'AUP ${item.aupId ?? "-"} • ${_storeLabel(context, item.store)}',
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
              const _MoreMenu(),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PlatformBadge.android(
                label: _platformBadgeLabel(context, true),
              ),
              _PlatformBadge.ios(
                label: _platformBadgeLabel(context, true),
              ),
              _StatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: 10),
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
                    l10n.publish_action_view_publish,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: tiny ? 13 : 14,
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

  Widget _tableRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 38,
            child: Row(
              children: [
                const _AppIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.appName?.trim().isNotEmpty == true
                            ? item.appName!
                            : l10n.publish_unknown_app,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'AUP ${item.aupId ?? "-"} • ${_storeLabel(context, item.store)}',
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
                _PlatformBadge.android(
                  label: _platformBadgeLabel(context, true),
                ),
                _PlatformBadge.ios(
                  label: _platformBadgeLabel(context, true),
                ),
              ],
            ),
          ),
          if (showVersion)
            Expanded(
              flex: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_androidVersionLine(context)),
                  const SizedBox(height: 6),
                  Text(_iosVersionLine(context)),
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
                  Text(
                    _prettyDate(item.requestedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'REQ-${item.id.toString().padLeft(6, "0")}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.publish_action_view_publish,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const _MoreMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _platformBadgeLabel(BuildContext context, bool ready) {
    final l10n = AppLocalizations.of(context)!;
    return ready ? l10n.owner_project_ready : l10n.status_pending;
  }

  String _storeLabel(BuildContext context, String store) {
    final l10n = AppLocalizations.of(context)!;
    final s = store.toUpperCase();

    if (s == 'PLAY_STORE') return l10n.publish_store_play;
    if (s == 'APP_STORE') return l10n.publish_store_app;
    return store;
  }

  String _androidVersionLine(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = item.androidVersionName?.trim();
    final code = item.androidVersionCode;

    if ((name == null || name.isEmpty) && code == null) {
      return '${l10n.owner_publish_platform_android}: —';
    }

    if (name != null && name.isNotEmpty && code != null) {
      return '${l10n.owner_publish_platform_android}: $name ($code)';
    }

    if (name != null && name.isNotEmpty) {
      return '${l10n.owner_publish_platform_android}: $name';
    }

    return '${l10n.owner_publish_platform_android}: $code';
  }

  String _iosVersionLine(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = item.iosVersionName?.trim();
    final build = item.iosBuildNumber;

    if ((name == null || name.isEmpty) && build == null) {
      return '${l10n.owner_publish_platform_ios}: —';
    }

    if (name != null && name.isNotEmpty && build != null) {
      return '${l10n.owner_publish_platform_ios}: $name ($build)';
    }

    if (name != null && name.isNotEmpty) {
      return '${l10n.owner_publish_platform_ios}: $name';
    }

    return '${l10n.owner_publish_platform_ios}: $build';
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

class _AppIcon extends StatelessWidget {
  const _AppIcon();

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
  final Color tint;

  const _PlatformBadge._({
    required this.icon,
    required this.label,
    required this.tint,
  });

  factory _PlatformBadge.android({required String label}) => _PlatformBadge._(
        icon: Icons.android_rounded,
        label: label,
        tint: Colors.green,
      );

  factory _PlatformBadge.ios({required String label}) => _PlatformBadge._(
        icon: Icons.apple,
        label: label,
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
            color: tint.withOpacity(.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tint,
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
    if (s == 'SUBMITTED' || s == 'IN_REVIEW') {
      c = cs.primary;
    } else if (s == 'APPROVED') {
      c = Colors.green;
    } else if (s == 'REJECTED') {
      c = Colors.red;
    } else if (s == 'PUBLISHED') {
      c = Colors.teal;
    } else {
      c = cs.secondary;
    }

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
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _statusLabel(context, status),
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

  String _statusLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return l10n.publish_status_submitted;
      case 'IN_REVIEW':
        return l10n.publish_status_in_review;
      case 'APPROVED':
        return l10n.publish_status_approved;
      case 'REJECTED':
        return l10n.publish_status_rejected;
      case 'PUBLISHED':
        return l10n.publish_status_published;
      case 'DRAFT':
        return l10n.publish_status_draft;
      default:
        return status;
    }
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      tooltip: l10n.common_more,
      onSelected: (_) {},
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'history',
          child: Text(l10n.publish_action_cicd_history_soon),
        ),
        PopupMenuItem(
          value: 'logs',
          child: Text(l10n.publish_action_view_logs_soon),
        ),
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