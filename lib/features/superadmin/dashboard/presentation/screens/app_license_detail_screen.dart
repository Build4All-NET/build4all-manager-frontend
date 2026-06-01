import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../data/models/super_admin_app_license_row.dart';

/// Read-only License detail page for the super admin.
///
/// Opened from [AppsLicensesScreen] by tapping a license card. It replaces the
/// list (full-page push) and the AppBar's automatic leading arrow returns to
/// the list. Intentionally has no action bar (Block / Mark-unpaid /
/// View-as-owner were removed); it is a focused, single-app read-only view.
class AppLicenseDetailScreen extends StatelessWidget {
  final SuperAdminAppLicenseRow item;

  /// When true the AppBar shows a ⋮ overflow with "Cancel License", which
  /// pops the page with the result `'cancel'` so the list can run the
  /// existing cancel flow and refresh.
  final bool canCancel;

  const AppLicenseDetailScreen({
    super.key,
    required this.item,
    this.canCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final eff = _effectiveStatus(context, item);
    final planLabel = _planLabel(l10n, item.planCode, item.planName);
    final isPending =
        (item.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (canCancel)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cancel') Navigator.of(context).pop('cancel');
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 18, color: cs.error),
                      const SizedBox(width: 10),
                      const Text('Cancel License'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // ---- identity ----
          Text(
            [
              item.ownerName ?? item.ownerUsername ?? '-',
              if ((item.ownerEmail ?? '').trim().isNotEmpty) item.ownerEmail!,
            ].join(' • '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              item.projectName ?? '-',
              if ((item.slug ?? '').trim().isNotEmpty) item.slug!,
              '#${item.aupId}',
            ].join(' • '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),

          // ---- headline status + plan + seats ----
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(context, eff.label, eff.color, icon: eff.icon),
              _chip(context, planLabel, cs.primary,
                  icon: Icons.workspace_premium_outlined),
              _chip(
                context,
                '${item.activeUsers ?? 0} / ${item.usersAllowed?.toString() ?? l10n.unlimitedLabel}',
                cs.secondary,
                icon: Icons.people_alt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---- pending request callout ----
          if (isPending)
            _section(
              context,
              title: l10n.app_licenses_request_status_label,
              color: Colors.orange,
              children: [
                _StatusBanner(
                  icon: Icons.schedule_rounded,
                  color: Colors.orange,
                  text: l10n.app_licenses_pending_request,
                ),
              ],
            ),

          // ---- subscription ----
          _section(
            context,
            title: l10n.subscriptionStatusLabel,
            children: [
              _row(context, l10n.planLabel, planLabel),
              _row(context, l10n.subscriptionStatusLabel,
                  _statusLabel(l10n, item.subscriptionStatus)),
              _row(context, l10n.periodEndLabel, _dateText(item.periodEnd)),
              _row(context, l10n.daysLeftLabel,
                  item.daysLeft?.toString() ?? '-'),
              _row(
                context,
                l10n.usersLabel,
                '${item.activeUsers ?? 0} / ${item.usersAllowed?.toString() ?? l10n.unlimitedLabel}',
              ),
              _row(context, l10n.remainingLabel,
                  item.usersRemaining?.toString() ?? l10n.unlimitedLabel),
            ],
          ),

          // ---- access ----
          _section(
            context,
            title: l10n.dashboardAccessLabel,
            children: [
              _row(
                context,
                l10n.dashboardAccessLabel,
                item.canAccessDashboard == true
                    ? l10n.yes
                    : item.canAccessDashboard == false
                        ? l10n.no
                        : l10n.unknownLabel,
              ),
              _row(context, l10n.blockingReasonLabel,
                  item.blockingReason ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  // ----- helpers -----

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (color ?? cs.outlineVariant).withOpacity(.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color ?? cs.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String text, Color color,
      {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _dateText(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _planLabel(AppLocalizations l10n, String? code, String? planName) {
    final raw = (code ?? '').toUpperCase();
    if (raw == 'FREE') return l10n.app_licenses_plan_free;
    if ((planName ?? '').trim().isNotEmpty) return planName!.trim();
    if ((code ?? '').trim().isNotEmpty) return code!;
    return l10n.unknownLabel;
  }

  String _statusLabel(AppLocalizations l10n, String? value) {
    final s = (value ?? '').toUpperCase();
    switch (s) {
      case 'ACTIVE':
        return l10n.common_status_active;
      case 'PENDING':
        return l10n.status_pending;
      case 'EXPIRED':
        return l10n.app_licenses_status_expired;
      case 'SUSPENDED':
        return l10n.app_licenses_status_suspended;
      case 'CANCELED':
      case 'CANCELLED':
        return l10n.app_licenses_status_canceled;
      default:
        return (value ?? '').trim().isEmpty ? l10n.unknownLabel : value!;
    }
  }

  _Eff _effectiveStatus(BuildContext context, SuperAdminAppLicenseRow item) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (item.canAccessDashboard == false) {
      return _Eff(l10n.app_licenses_stat_blocked, cs.error, Icons.block_rounded);
    }
    if ((item.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING') {
      return _Eff(
          l10n.status_pending, Colors.orange, Icons.schedule_rounded);
    }
    final s = (item.subscriptionStatus ?? '').toUpperCase();
    switch (s) {
      case 'ACTIVE':
        return _Eff(l10n.common_status_active, Colors.green,
            Icons.verified_rounded);
      case 'SCHEDULED':
        return _Eff('Scheduled', Colors.blue, Icons.event_rounded);
      case 'EXPIRED':
        return _Eff(l10n.app_licenses_status_expired, cs.error,
            Icons.hourglass_disabled_rounded);
      case 'CANCELED':
      case 'CANCELLED':
        return _Eff(l10n.app_licenses_status_canceled, cs.error,
            Icons.cancel_outlined);
      case 'SUSPENDED':
        return _Eff(l10n.app_licenses_status_suspended, cs.error,
            Icons.pause_circle_outline_rounded);
    }
    if ((item.planCode ?? '').toUpperCase() == 'FREE') {
      return _Eff(l10n.app_licenses_plan_free, cs.primary,
          Icons.workspace_premium_outlined);
    }
    return _Eff(l10n.unknownLabel, cs.secondary, Icons.help_outline_rounded);
  }
}

class _Eff {
  final String label;
  final Color color;
  final IconData icon;
  const _Eff(this.label, this.color, this.icon);
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
