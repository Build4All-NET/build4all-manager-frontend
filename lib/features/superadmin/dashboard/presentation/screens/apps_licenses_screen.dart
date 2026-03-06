import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/models/super_admin_app_license_row.dart';
import '../../data/services/licensing_api.dart';

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
  _LicenseFilter _filter = _LicenseFilter.all;

  final Set<int> _expandedIds = <int>{};

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
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractError(e);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final error = data['error']?.toString();
      final message = data['message']?.toString();
      final code = data['code']?.toString();

      if (error != null && error.trim().isNotEmpty) return error;
      if (message != null && message.trim().isNotEmpty) return message;
      if (code != null && code.trim().isNotEmpty) return code;
    }

    return e.message ?? 'Request failed';
  }

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
    final plan = (item.planCode ?? '').toUpperCase();

    switch (_filter) {
      case _LicenseFilter.all:
        return true;
      case _LicenseFilter.pending:
        return (item.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';
      case _LicenseFilter.blocked:
        return item.canAccessDashboard == false;
      case _LicenseFilter.free:
        return plan == 'FREE';
      case _LicenseFilter.proHosted:
        return plan == 'PRO_HOSTEDB';
      case _LicenseFilter.dedicated:
        return plan == 'DEDICATED' || item.requiresDedicatedServer == true;
    }
  }

  List<SuperAdminAppLicenseRow> get _filteredItems {
    final list = _items
        .where((e) => _matchesSearch(e) && _matchesFilter(e))
        .toList();

    list.sort((a, b) {
      final aPending =
          (a.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';
      final bPending =
          (b.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';

      if (aPending != bPending) {
        return aPending ? -1 : 1;
      }

      final aBlocked = a.canAccessDashboard == false;
      final bBlocked = b.canAccessDashboard == false;

      if (aBlocked != bBlocked) {
        return aBlocked ? -1 : 1;
      }

      return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
    });

    return list;
  }

  void _toggleExpanded(int aupId) {
    setState(() {
      if (_expandedIds.contains(aupId)) {
        _expandedIds.remove(aupId);
      } else {
        _expandedIds.add(aupId);
      }
    });
  }

  String _dateText(DateTime? date) {
    if (date == null) return '-';
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _usersText(SuperAdminAppLicenseRow item, AppLocalizations l10n) {
    final active = item.activeUsers?.toString() ?? '0';
    final allowed = item.usersAllowed?.toString() ?? l10n.unlimitedLabel;
    return '$active / $allowed';
  }

  String _yesNo(bool? value, AppLocalizations l10n) {
    if (value == true) return l10n.yes;
    if (value == false) return l10n.no;
    return l10n.unknownLabel;
  }

  Color _statusColor(BuildContext context, String? value) {
    final cs = Theme.of(context).colorScheme;
    final s = (value ?? '').toUpperCase();

    switch (s) {
      case 'ACTIVE':
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FREE':
        return cs.primary;
      case 'PRO_HOSTEDB':
        return Colors.blue;
      case 'DEDICATED':
        return Colors.deepPurple;
      case 'EXPIRED':
      case 'REJECTED':
      case 'SUSPENDED':
      case 'DELETED':
      case 'CANCELED':
        return cs.error;
      default:
        return cs.secondary;
    }
  }

  Widget _chip(
    BuildContext context,
    String text,
    Color color, {
    IconData? icon,
  }) {
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

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final pendingCount = _items
        .where((e) => (e.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING')
        .length;
    final blockedCount =
        _items.where((e) => e.canAccessDashboard == false).length;
    final freeCount =
        _items.where((e) => (e.planCode ?? '').toUpperCase() == 'FREE').length;
    final proCount = _items
        .where((e) => (e.planCode ?? '').toUpperCase() == 'PRO_HOSTEDB')
        .length;
    final dedicatedCount = _items
        .where((e) => (e.planCode ?? '').toUpperCase() == 'DEDICATED')
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appLicensesTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appLicensesSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.searchAppsHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _filterChip(
                context,
                label: 'All',
                selected: _filter == _LicenseFilter.all,
                icon: Icons.apps_rounded,
                onTap: () => setState(() => _filter = _LicenseFilter.all),
              ),
              _filterChip(
                context,
                label: 'Pending',
                selected: _filter == _LicenseFilter.pending,
                icon: Icons.schedule_rounded,
                onTap: () => setState(() => _filter = _LicenseFilter.pending),
              ),
              _filterChip(
                context,
                label: 'Blocked',
                selected: _filter == _LicenseFilter.blocked,
                icon: Icons.block_rounded,
                onTap: () => setState(() => _filter = _LicenseFilter.blocked),
              ),
              _filterChip(
                context,
                label: 'Free',
                selected: _filter == _LicenseFilter.free,
                icon: Icons.workspace_premium_outlined,
                onTap: () => setState(() => _filter = _LicenseFilter.free),
              ),
              _filterChip(
                context,
                label: 'Pro Hosted',
                selected: _filter == _LicenseFilter.proHosted,
                icon: Icons.cloud_done_rounded,
                onTap: () => setState(() => _filter = _LicenseFilter.proHosted),
              ),
              _filterChip(
                context,
                label: 'Dedicated',
                selected: _filter == _LicenseFilter.dedicated,
                icon: Icons.dns_rounded,
                onTap: () => setState(() => _filter = _LicenseFilter.dedicated),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(context, '${_items.length} total', cs.primary,
                  icon: Icons.inventory_2_outlined),
              _chip(context, '$pendingCount pending', Colors.orange,
                  icon: Icons.schedule_rounded),
              _chip(context, '$blockedCount blocked', cs.error,
                  icon: Icons.block_rounded),
              _chip(context, '$freeCount free', cs.primary,
                  icon: Icons.workspace_premium_outlined),
              _chip(context, '$proCount pro hosted', Colors.blue,
                  icon: Icons.cloud_done_rounded),
              _chip(context, '$dedicatedCount dedicated', Colors.deepPurple,
                  icon: Icons.dns_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, SuperAdminAppLicenseRow item) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final isPending =
        (item.upgradeRequestStatus ?? '').toUpperCase() == 'PENDING';
    final isBlocked = item.canAccessDashboard == false;
    final isExpanded = _expandedIds.contains(item.aupId);

    final planColor = _statusColor(context, item.planCode);
    final subColor = _statusColor(context, item.subscriptionStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? Colors.orange.withOpacity(.28)
              : isBlocked
                  ? cs.error.withOpacity(.24)
                  : cs.outlineVariant.withOpacity(.45),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              item.ownerName ?? item.ownerUsername ?? '-',
                              item.projectName ?? '-',
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggleExpanded(item.aupId),
                      icon: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      context,
                      item.planCode ?? l10n.unknownLabel,
                      planColor,
                      icon: Icons.workspace_premium_outlined,
                    ),
                    _chip(
                      context,
                      item.subscriptionStatus ?? l10n.unknownLabel,
                      subColor,
                      icon: Icons.verified_rounded,
                    ),
                    if (isPending)
                      _chip(
                        context,
                        'Pending Request',
                        Colors.orange,
                        icon: Icons.schedule_rounded,
                      ),
                    if (isBlocked)
                      _chip(
                        context,
                        'Blocked',
                        cs.error,
                        icon: Icons.block_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;
                    final boxes = [
                      _metricCard(
                        context,
                        icon: Icons.people_alt_rounded,
                        label: l10n.usersLabel,
                        value: _usersText(item, l10n),
                        color: cs.primary,
                      ),
                      _metricCard(
                        context,
                        icon: Icons.event_available_rounded,
                        label: l10n.daysLeftLabel,
                        value: item.daysLeft?.toString() ?? '-',
                        color: Colors.teal,
                      ),
                      _metricCard(
                        context,
                        icon: item.canAccessDashboard == false
                            ? Icons.lock_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        label: l10n.dashboardAccessLabel,
                        value: item.canAccessDashboard == true
                            ? l10n.yes
                            : item.canAccessDashboard == false
                                ? l10n.no
                                : l10n.unknownLabel,
                        color: item.canAccessDashboard == false
                            ? cs.error
                            : Colors.green,
                      ),
                    ];

                    if (compact) {
                      return Column(
                        children: [
                          for (int i = 0; i < boxes.length; i++) ...[
                            boxes[i],
                            if (i != boxes.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: boxes[0]),
                        const SizedBox(width: 10),
                        Expanded(child: boxes[1]),
                        const SizedBox(width: 10),
                        Expanded(child: boxes[2]),
                      ],
                    );
                  },
                ),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  _StatusBanner(
                    icon: Icons.schedule_rounded,
                    color: Colors.orange,
                    text: 'This app has a pending upgrade request.',
                  ),
                ],
                if (isBlocked) ...[
                  const SizedBox(height: 10),
                  _StatusBanner(
                    icon: Icons.warning_amber_rounded,
                    color: cs.error,
                    text:
                        'Blocked: ${item.blockingReason ?? l10n.unknownLabel}',
                  ),
                ],
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: cs.outlineVariant.withOpacity(.55)),
                  _detailRow(context, l10n.idLabel, item.aupId.toString()),
                  _detailRow(context, l10n.slugLabel, item.slug ?? '-'),
                  _detailRow(context, l10n.emailLabel, item.ownerEmail ?? '-'),
                  _detailRow(context, l10n.projectLabel, item.projectName ?? '-'),
                  _detailRow(
                    context,
                    l10n.planLabel,
                    item.planName ?? item.planCode ?? '-',
                  ),
                  _detailRow(
                    context,
                    l10n.subscriptionStatusLabel,
                    item.subscriptionStatus ?? '-',
                  ),
                  _detailRow(
                    context,
                    l10n.periodEndLabel,
                    _dateText(item.periodEnd),
                  ),
                  _detailRow(
                    context,
                    l10n.remainingLabel,
                    item.usersRemaining?.toString() ?? l10n.unlimitedLabel,
                  ),
                  _detailRow(
                    context,
                    l10n.requiresDedicatedServerLabel,
                    _yesNo(item.requiresDedicatedServer, l10n),
                  ),
                  _detailRow(
                    context,
                    l10n.dedicatedInfraReadyLabel,
                    _yesNo(item.dedicatedInfraReady, l10n),
                  ),
                  _detailRow(
                    context,
                    l10n.blockingReasonLabel,
                    item.blockingReason ?? '-',
                  ),
                  _detailRow(
                    context,
                    'Request Status',
                    item.upgradeRequestStatus ?? '-',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            tooltip: l10n.refresh,
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
                        retryLabel: l10n.retry,
                        onRetry: _load,
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _buildTopPanel(context),
                      const SizedBox(height: 16),
                      if (items.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.inbox_outlined,
                          title: _query.trim().isEmpty
                              ? l10n.noAppsLicensesFound
                              : l10n.noSearchResults,
                          subtitle: _query.trim().isEmpty
                              ? 'No app license rows are available yet.'
                              : 'Try another search or filter combination.',
                        )
                      else
                        ...items.map((e) => _buildCard(context, e)),
                    ],
                  ),
      ),
    );
  }
}

enum _LicenseFilter {
  all,
  pending,
  blocked,
  free,
  proHosted,
  dedicated,
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
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
          borderRadius: BorderRadius.circular(22),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        box(190),
        const SizedBox(height: 16),
        box(220),
        const SizedBox(height: 14),
        box(220),
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
          Icon(
            Icons.error_outline_rounded,
            size: 54,
            color: cs.error,
          ),
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
          Icon(
            icon,
            size: 54,
            color: cs.onSurfaceVariant,
          ),
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