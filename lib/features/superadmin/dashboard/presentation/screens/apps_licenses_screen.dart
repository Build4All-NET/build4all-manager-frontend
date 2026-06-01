import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/models/super_admin_app_license_row.dart';
import '../../data/services/licensing_api.dart';
import 'app_license_detail_screen.dart';

// Filter tokens. A filter is either "all", one of these special tokens, or a
// plain plan code (e.g. "FREE", "BASIC", "SMART") derived from the data.
const String _kAll = '__ALL__';
const String _kPending = '__PENDING__';
const String _kBlocked = '__BLOCKED__';

class AppsLicensesScreen extends StatefulWidget {
  const AppsLicensesScreen({super.key});

  @override
  State<AppsLicensesScreen> createState() => _AppsLicensesScreenState();
}

class _AppsLicensesScreenState extends State<AppsLicensesScreen> {
  late final Dio _dio;
  late final LicensingApi _api;

  bool _loading = true;
  String? _error;

  List<SuperAdminAppLicenseRow> _items = const [];
  String _query = '';
  String _filter = _kAll;

  int? _cancelingAupId;

  @override
  void initState() {
    super.initState();
    _dio = DioClient.ensure();
    _api = LicensingApi(_dio);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _api.listAppsLicenses();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _cancelLicense(SuperAdminAppLicenseRow item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel License'),
        content: Text(
          'Are you sure you want to cancel the license for ${item.appName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _cancelingAupId = item.aupId;
    });

    try {
      final res = await _api.cancelLicense(item.aupId);
      if (!mounted) return;

      String message = 'Done successfully';
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final backendMessage = data['message']?.toString();
        if (backendMessage != null && backendMessage.trim().isNotEmpty) {
          message = backendMessage;
        }
      }
      AppToast.success(context, message);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, ApiErrorHandler.message(e));
    } finally {
      if (!mounted) return;
      setState(() {
        _cancelingAupId = null;
      });
    }
  }

  Future<void> _openDetail(SuperAdminAppLicenseRow item) async {
    final isActive =
        (item.subscriptionStatus ?? '').toUpperCase() == 'ACTIVE';
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AppLicenseDetailScreen(
          item: item,
          canCancel: isActive && _cancelingAupId == null,
        ),
      ),
    );
    if (result == 'cancel') {
      await _cancelLicense(item);
    }
  }

  // ----- filtering / sorting -----

  bool _matchesSearch(SuperAdminAppLicenseRow item) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final haystack = [
      item.appName,
      item.slug,
      item.appStatus,
      item.ownerName,
      item.ownerEmail,
      item.ownerUsername,
      item.projectName,
      item.planCode,
      item.planName,
      item.subscriptionStatus,
      item.blockingReason,
      item.upgradeRequestStatus,
    ].whereType<String>().join(' ').toLowerCase();

    return haystack.contains(q);
  }

  bool _matchesFilter(SuperAdminAppLicenseRow item) {
    switch (_filter) {
      case _kAll:
        return true;
      case _kPending:
        return (item.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';
      case _kBlocked:
        return item.canAccessDashboard == false;
      default:
        return (item.planCode ?? '').toUpperCase() == _filter;
    }
  }

  List<SuperAdminAppLicenseRow> get _filteredItems {
    final list = _items
        .where((e) => _matchesSearch(e) && _matchesFilter(e))
        .toList();

    list.sort((a, b) {
      final byRank = _attentionRank(a).compareTo(_attentionRank(b));
      if (byRank != 0) return byRank;
      return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
    });

    return list;
  }

  // Lower rank = higher in the list ("needs attention first").
  int _attentionRank(SuperAdminAppLicenseRow e) {
    if (e.canAccessDashboard == false) return 0; // blocked
    if ((e.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING') return 1;
    final s = (e.subscriptionStatus ?? '').toUpperCase();
    if (s == 'EXPIRED') return 2;
    if (s == 'CANCELED' || s == 'CANCELLED') return 3;
    if (s == 'SCHEDULED') return 4;
    if (s == 'ACTIVE') return 5;
    return 6;
  }

  // Distinct plan codes present in the data (FREE first, then alphabetical).
  List<String> get _planCodes {
    final set = <String>{};
    for (final e in _items) {
      final c = (e.planCode ?? '').toUpperCase().trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList();
    list.sort((a, b) {
      if (a == 'FREE') return -1;
      if (b == 'FREE') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  // ----- formatting -----

  String _prettyPlan(AppLocalizations l10n, String code) {
    if (code == 'FREE') return l10n.app_licenses_plan_free;
    if (code.isEmpty) return l10n.unknownLabel;
    return code[0].toUpperCase() + code.substring(1).toLowerCase();
  }

  String _usersText(SuperAdminAppLicenseRow item, AppLocalizations l10n) {
    final active = item.activeUsers?.toString() ?? '0';
    final allowed = item.usersAllowed?.toString() ?? l10n.unlimitedLabel;
    return '$active / $allowed';
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

  // ----- small widgets -----

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

  Widget _planFilterChip(BuildContext context,
      {required String label, required bool selected, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? cs.onPrimary : cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTopPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.searchAppsHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              isDense: true,
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _planFilterChip(
                context,
                label: l10n.app_licenses_filter_all,
                selected: _filter == _kAll,
                onTap: () => setState(() => _filter = _kAll),
              ),
              for (final code in _planCodes)
                _planFilterChip(
                  context,
                  label: _prettyPlan(l10n, code),
                  selected: _filter == code,
                  onTap: () => setState(() => _filter = code),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionStrip(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final pendingCount = _items
        .where((e) => (e.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING')
        .length;
    final blockedCount =
        _items.where((e) => e.canAccessDashboard == false).length;

    if (pendingCount == 0 && blockedCount == 0) {
      return const SizedBox.shrink();
    }

    Widget item(int count, String token, Color color, IconData icon) {
      final selected = _filter == token;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _filter = selected ? _kAll : token),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: color.withOpacity(selected ? .16 : .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: color.withOpacity(selected ? .55 : .25)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text('$count',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: color.withOpacity(.7)),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (pendingCount > 0)
            item(pendingCount, _kPending, Colors.orange,
                Icons.schedule_rounded),
          if (pendingCount > 0 && blockedCount > 0) const SizedBox(width: 8),
          if (blockedCount > 0)
            item(blockedCount, _kBlocked, cs.error, Icons.block_rounded),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, SuperAdminAppLicenseRow item) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final eff = _effectiveStatus(context, item);
    final planCode = (item.planCode ?? '').toUpperCase();
    final planLabel = _prettyPlan(l10n, planCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: eff.color.withOpacity(.30)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(item),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: eff.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _chip(context, eff.label, eff.color, icon: eff.icon),
                          const Spacer(),
                          _chip(context, planLabel, cs.primary),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          item.ownerName ?? item.ownerUsername ?? '-',
                          item.projectName ?? '-',
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.people_alt_rounded,
                              size: 15, color: cs.onSurfaceVariant),
                          const SizedBox(width: 5),
                          Text(
                            _usersText(item, l10n),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 14),
                          if (_showDaysLeft(item)) ...[
                            Icon(Icons.event_available_rounded,
                                size: 15, color: cs.onSurfaceVariant),
                            const SizedBox(width: 5),
                            Text(
                              '${item.daysLeft} ${l10n.daysLeftLabel}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Only count down when the app is genuinely active (hide for
  // blocked / expired / canceled, per the design).
  bool _showDaysLeft(SuperAdminAppLicenseRow item) {
    if (item.daysLeft == null) return false;
    if (item.canAccessDashboard == false) return false;
    final s = (item.subscriptionStatus ?? '').toUpperCase();
    return s == 'ACTIVE' || s == 'SCHEDULED' || s == 'FREE' || s.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appLicensesTitle),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: l10n.common_refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const _LicensesLoadingView()
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ScreenErrorCard(
                        title: l10n.failedToLoadAppLicenses,
                        message: _error!,
                        retryLabel: l10n.common_retry,
                        onRetry: _load,
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildTopPanel(context),
                      _buildActionStrip(context),
                      const SizedBox(height: 14),
                      if (items.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.inbox_outlined,
                          title: _query.trim().isEmpty
                              ? l10n.noAppsLicensesFound
                              : l10n.noSearchResults,
                          subtitle: _query.trim().isEmpty
                              ? l10n.app_licenses_empty_subtitle
                              : l10n.app_licenses_empty_search_subtitle,
                        )
                      else
                        ...items.map((e) => _buildCard(context, e)),
                    ],
                  ),
      ),
    );
  }
}

class _Eff {
  final String label;
  final Color color;
  final IconData icon;
  const _Eff(this.label, this.color, this.icon);
}

class _LicensesLoadingView extends StatelessWidget {
  const _LicensesLoadingView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget box(double h) {
      return Container(
        height: h,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        box(120),
        const SizedBox(height: 14),
        box(120),
        const SizedBox(height: 12),
        box(120),
      ],
    );
  }
}

class _ScreenErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ScreenErrorCard({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.error.withOpacity(.22)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, size: 54, color: cs.error),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(.45)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 54, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
