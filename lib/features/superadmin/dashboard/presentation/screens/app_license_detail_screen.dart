import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter/material.dart';

import '../../data/models/super_admin_app_license_detail.dart';
import '../../data/models/super_admin_app_license_row.dart';
import '../../data/services/licensing_api.dart';

/// Read-only License detail page for the super admin.
///
/// Opened from [AppsLicensesScreen] by tapping a license card (full-page push;
/// the AppBar's leading arrow returns to the list). Renders the summary
/// instantly from the passed row, then loads the subscription timeline and
/// payment ledger from GET /licensing/apps/{aupId}/license-detail.
///
/// Intentionally has no Block / Mark-unpaid / View-as-owner action bar. The
/// pre-existing Cancel-License action is offered in the AppBar overflow and
/// returns `'cancel'` so the list runs the existing flow + refresh.
class AppLicenseDetailScreen extends StatefulWidget {
  final SuperAdminAppLicenseRow item;
  final bool canCancel;

  const AppLicenseDetailScreen({
    super.key,
    required this.item,
    this.canCancel = false,
  });

  @override
  State<AppLicenseDetailScreen> createState() => _AppLicenseDetailScreenState();
}

class _AppLicenseDetailScreenState extends State<AppLicenseDetailScreen> {
  late final LicensingApi _api;

  bool _loading = true;
  String? _error;
  SuperAdminAppLicenseDetail? _detail;

  SuperAdminAppLicenseRow get item => widget.item;

  @override
  void initState() {
    super.initState();
    _api = LicensingApi(DioClient.ensure());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _api.appLicenseDetail(item.aupId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiErrorHandler.message(e);
        _loading = false;
      });
    }
  }

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
        title: Text(item.appName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.canCancel)
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // identity
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

            // headline status + plan + seats
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

            // pending request callout
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

            // ---- timeline ----
            _section(
              context,
              title: l10n.license_timeline_title,
              children: [_buildTimeline(context)],
            ),

            // current subscription
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

            // ---- payment ledger ----
            _section(
              context,
              title: l10n.super_payment_title,
              children: [_buildLedger(context)],
            ),

            // access
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
      ),
    );
  }

  // ----- timeline -----

  Widget _buildTimeline(BuildContext context) {
    if (_loading) return const _MiniLoader();
    if (_error != null) return _MiniError(message: _error!, onRetry: _load);

    final periods = _detail?.subscriptions ?? const <LicensePeriod>[];
    if (periods.isEmpty) {
      return Text('-',
          style: Theme.of(context).textTheme.bodyMedium);
    }

    // proportional bar
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          for (final p in periods)
            Expanded(
              flex: _spanDays(p),
              child: Container(
                height: 30,
                color: _statusColor(context, p.status),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  _shortPlan(p.planCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar,
        const SizedBox(height: 12),
        for (final p in periods) _periodRow(context, p),
      ],
    );
  }

  Widget _periodRow(BuildContext context, LicensePeriod p) {
    final l10n = AppLocalizations.of(context)!;
    final color = _statusColor(context, p.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              _planLabel(l10n, p.planCode, p.planName),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${_dateText(p.periodStart)} → ${_dateText(p.periodEnd)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  int _spanDays(LicensePeriod p) {
    if (p.periodStart == null || p.periodEnd == null) return 1;
    final d = p.periodEnd!.difference(p.periodStart!).inDays;
    return d < 1 ? 1 : d;
  }

  // ----- ledger -----

  Widget _buildLedger(BuildContext context) {
    if (_loading) return const _MiniLoader();
    if (_error != null) return _MiniError(message: _error!, onRetry: _load);

    final payments = _detail?.payments ?? const <LicensePayment>[];
    if (payments.isEmpty) {
      return Text('-', style: Theme.of(context).textTheme.bodyMedium);
    }
    return Column(
      children: [for (final p in payments) _paymentRow(context, p)],
    );
  }

  Widget _paymentRow(BuildContext context, LicensePayment p) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final color = _paymentStatusColor(context, p.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (p.planCode != null) _shortPlan(p.planCode),
                    if ((p.provider ?? '').isNotEmpty) _prettyProvider(p.provider!),
                  ].join(' • '),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateText(p.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(p.amount, p.currency),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              _chip(context, _paymentStatusLabel(l10n, p.status), color),
            ],
          ),
        ],
      ),
    );
  }

  // ----- shared widgets -----

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
        border: Border.all(color: (color ?? cs.outlineVariant).withOpacity(.4)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  // ----- formatting -----

  String _dateText(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _money(double? amount, String? currency) {
    if (amount == null) return '-';
    final cur = (currency ?? '').toUpperCase();
    final n = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return cur.isEmpty ? n : '$n $cur';
  }

  String _shortPlan(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    if (c.isEmpty) return '-';
    return c[0].toUpperCase() + c.substring(1).toLowerCase();
  }

  String _prettyProvider(String provider) {
    final p = provider.trim().toLowerCase();
    switch (p) {
      case 'stripe':
        return 'Stripe';
      case 'paypal':
        return 'PayPal';
      case 'mpgs':
        return 'MPGS';
      case 'cash':
      case 'manual':
        return 'Cash';
      default:
        return provider;
    }
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
      case 'SCHEDULED':
        return l10n.subscription_status_scheduled;
      default:
        return (value ?? '').trim().isEmpty ? l10n.unknownLabel : value!;
    }
  }

  Color _statusColor(BuildContext context, String? status) {
    final cs = Theme.of(context).colorScheme;
    switch ((status ?? '').toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'SCHEDULED':
        return Colors.blue;
      case 'PENDING':
        return Colors.orange;
      case 'EXPIRED':
      case 'CANCELED':
      case 'CANCELLED':
      case 'SUSPENDED':
        return cs.error;
      default:
        return cs.outline;
    }
  }

  String _paymentStatusLabel(AppLocalizations l10n, String? status) {
    final s = (status ?? '').toUpperCase();
    switch (s) {
      case 'PAID':
        return l10n.payment_status_paid;
      case 'PENDING':
        return l10n.status_pending;
      case 'FAILED':
        return l10n.payment_status_failed;
      case 'CANCELED':
      case 'CANCELLED':
        return l10n.app_licenses_status_canceled;
      default:
        return s.isEmpty ? l10n.unknownLabel : s;
    }
  }

  Color _paymentStatusColor(BuildContext context, String? status) {
    final cs = Theme.of(context).colorScheme;
    switch ((status ?? '').toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
      case 'CANCELED':
      case 'CANCELLED':
        return cs.error;
      default:
        return cs.secondary;
    }
  }

  _Eff _effectiveStatus(BuildContext context, SuperAdminAppLicenseRow item) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (item.canAccessDashboard == false) {
      return _Eff(l10n.app_licenses_stat_blocked, cs.error, Icons.block_rounded);
    }
    if ((item.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING') {
      return _Eff(l10n.status_pending, Colors.orange, Icons.schedule_rounded);
    }
    final s = (item.subscriptionStatus ?? '').toUpperCase();
    switch (s) {
      case 'ACTIVE':
        return _Eff(
            l10n.common_status_active, Colors.green, Icons.verified_rounded);
      case 'SCHEDULED':
        return _Eff(l10n.subscription_status_scheduled, Colors.blue,
            Icons.event_rounded);
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

class _MiniLoader extends StatelessWidget {
  const _MiniLoader();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _MiniError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _MiniError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.error),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context)!.common_retry),
        ),
      ],
    );
  }
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
