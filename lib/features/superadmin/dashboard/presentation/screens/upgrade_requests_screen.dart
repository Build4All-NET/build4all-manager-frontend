import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../dashboard/data/services/licensing_api.dart';

class SuperAdminUpgradeRequestsScreen extends StatefulWidget {
  const SuperAdminUpgradeRequestsScreen({super.key});

  @override
  State<SuperAdminUpgradeRequestsScreen> createState() =>
      _SuperAdminUpgradeRequestsScreenState();
}

enum _UpgradeView { pending, recentlyPaid }

class _SuperAdminUpgradeRequestsScreenState
    extends State<SuperAdminUpgradeRequestsScreen> {
  late final Dio _dio;
  late final LicensingApi _api;

  bool _loading = true;
  String? _error;

  _UpgradeView _view = _UpgradeView.pending;
  List<UpgradeRequestRow> _items = const [];
  final Set<int> _busyIds = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _dio = DioClient.ensure();
    _api = LicensingApi(_dio);
    _load();
  }

  void _toast(String msg, {bool error = false}) {
    if (msg.trim().isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (error) {
        AppToast.error(context, msg);
      } else {
        AppToast.show(context, msg);
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = _view == _UpgradeView.pending
          ? await _api.pendingUpgradeRequests()
          : await _api.recentlyApprovedUpgradeRequests();
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(UpgradeRequestRow.fromJson).toList();

      items.sort(
        (a, b) => (b.requestedAt ?? DateTime(1970))
            .compareTo(a.requestedAt ?? DateTime(1970)),
      );

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      final msg = ApiErrorHandler.message(e);
      if (!mounted) return;
      setState(() {
        _error = msg;
        _loading = false;
      });
      _toast(msg, error: true);
    }
  }

  void _switchView(_UpgradeView next) {
    if (next == _view) return;
    setState(() {
      _view = next;
      _items = const [];
    });
    _load();
  }

  Future<void> _markUnpaid(UpgradeRequestRow r) async {
    setState(() => _busyIds.add(r.id));
    try {
      await _api.markUpgradeRequestUnpaid(r.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x.id == r.id));
      _toast('Reversed — request is back in the pending queue');
    } catch (e) {
      _toast(ApiErrorHandler.message(e), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(r.id));
    }
  }

  Future<void> _markPaid(UpgradeRequestRow r) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _busyIds.add(r.id));
    try {
      await _api.markUpgradeRequestPaid(r.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x.id == r.id));
      _toast(l10n.upgrade_requests_approve_success);
    } catch (e) {
      _toast(ApiErrorHandler.message(e), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(r.id));
    }
  }

  Future<void> _reject(UpgradeRequestRow r) async {
    final l10n = AppLocalizations.of(context)!;
    final note = await _showRejectDialog();

    if (note == null) return;

    setState(() => _busyIds.add(r.id));
    try {
      await _api.rejectUpgradeRequest(
        r.id,
        note: note.trim().isEmpty ? null : note.trim(),
      );
      if (!mounted) return;
      setState(() => _items.removeWhere((x) => x.id == r.id));
      _toast(l10n.upgrade_requests_reject_success);
    } catch (e) {
      _toast(ApiErrorHandler.message(e), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(r.id));
    }
  }

  Future<String?> _showRejectDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final c = TextEditingController();

    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.upgrade_requests_reject_title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.upgrade_requests_reject_hint,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.upgrade_requests_note_optional,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: Text(l10n.common_submit),
            ),
          ],
        );
      },
    );
  }

  List<UpgradeRequestRow> get _filteredItems {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items.where((r) {
      final text = [
        r.appName,
        r.slug,
        r.requestedPlanCode,
        '${r.id}',
        '${r.aupId}',
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.upgrade_requests_title),
        actions: [
          IconButton(
            tooltip: l10n.common_retry,
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const _UpgradeLoadingView()
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ScreenErrorCard(
                        title: l10n.common_error,
                        message: _error!,
                        retryLabel: l10n.common_retry,
                        onRetry: _load,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _UpgradeHeroPanel(
                        total: _items.length,
                        filtered: items.length,
                        onSearch: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: 12),
                      _ViewSwitcher(
                        current: _view,
                        onChange: _switchView,
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.inbox_rounded,
                          title: _query.trim().isEmpty
                              ? (_view == _UpgradeView.pending
                                  ? l10n.upgrade_requests_empty
                                  : 'No recent cash approvals')
                              : l10n.upgrade_requests_empty_search_title,
                          subtitle: _query.trim().isEmpty
                              ? (_view == _UpgradeView.pending
                                  ? l10n.upgrade_requests_empty_sub
                                  : "Approvals from the last 7 days show up here so you can undo them.")
                              : l10n.upgrade_requests_empty_search_subtitle,
                        )
                      else
                        ...items.map((r) {
                          final busy = _busyIds.contains(r.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ProUpgradeRequestCard(
                              row: r,
                              busy: busy,
                              pending: _view == _UpgradeView.pending,
                              onMarkPaid: busy ? null : () => _markPaid(r),
                              onReject: busy ? null : () => _reject(r),
                              onMarkUnpaid:
                                  busy ? null : () => _markUnpaid(r),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
      floatingActionButton: !_loading && _error == null
          ? FloatingActionButton.extended(
              onPressed: () => _toast(
                l10n.upgrade_requests_visible_count(items.length.toString()),
              ),
              icon: const Icon(Icons.pending_actions_rounded),
              label: Text('${items.length}'),
            )
          : null,
    );
  }
}

class _UpgradeHeroPanel extends StatelessWidget {
  final int total;
  final int filtered;
  final ValueChanged<String> onSearch;

  const _UpgradeHeroPanel({
    required this.total,
    required this.filtered,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(.10),
            cs.secondary.withOpacity(.08),
            cs.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.outlineVariant.withOpacity(.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.upgrade_rounded,
                  color: cs.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.upgrade_requests_title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.upgrade_requests_hero_subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _TinyStatChip(
                icon: Icons.inventory_2_outlined,
                label: l10n.upgrade_requests_stat_total,
                value: '$total',
                color: cs.primary,
              ),
              _TinyStatChip(
                icon: Icons.visibility_outlined,
                label: l10n.upgrade_requests_stat_shown,
                value: '$filtered',
                color: cs.secondary,
              ),
              _TinyStatChip(
                icon: Icons.schedule_rounded,
                label: l10n.upgrade_requests_stat_pending,
                value: '$total',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.upgrade_requests_search_hint,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProUpgradeRequestCard extends StatelessWidget {
  final UpgradeRequestRow row;
  final bool busy;
  final bool pending;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onReject;
  final VoidCallback? onMarkUnpaid;

  const _ProUpgradeRequestCard({
    required this.row,
    required this.busy,
    required this.pending,
    required this.onMarkPaid,
    required this.onReject,
    required this.onMarkUnpaid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final appTitle = row.appName.trim().isNotEmpty
        ? row.appName.trim()
        : (row.slug.trim().isNotEmpty ? row.slug.trim() : '—');

    String fmtDate(DateTime? dt) {
      if (dt == null) return '—';
      final d = dt.toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
    }

    Widget softChip(String text, Color color, {IconData? icon}) {
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

    Widget infoTile({
      required IconData icon,
      required String label,
      required String value,
      required Color color,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
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

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(.26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  appTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                softChip(
                  l10n.upgrade_requests_status_pending,
                  Colors.orange,
                  icon: Icons.schedule_rounded,
                ),
                softChip(
                  row.requestedPlanCode.isEmpty ? '—' : row.requestedPlanCode,
                  cs.primary,
                  icon: Icons.workspace_premium_outlined,
                ),
                if (row.billingCycle.isNotEmpty)
                  softChip(
                    row.billingCycle,
                    Colors.indigo,
                    icon: row.billingCycle.toUpperCase() == 'YEARLY'
                        ? Icons.calendar_today_rounded
                        : Icons.calendar_view_month_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              row.slug.trim().isNotEmpty
                  ? row.slug
                  : l10n.upgrade_requests_no_slug_available,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final tiles = [
                  infoTile(
                    icon: Icons.confirmation_number_outlined,
                    label: l10n.upgrade_requests_request,
                    value: '#${row.id}',
                    color: cs.primary,
                  ),
                  infoTile(
                    icon: Icons.apps_rounded,
                    label: l10n.upgrade_requests_aup,
                    value: '${row.aupId}',
                    color: cs.secondary,
                  ),
                  infoTile(
                    icon: Icons.access_time_rounded,
                    label: l10n.upgrade_requests_requested_at,
                    value: fmtDate(row.requestedAt),
                    color: Colors.teal,
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (int i = 0; i < tiles.length; i++) ...[
                        tiles[i],
                        if (i != tiles.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: 10),
                    Expanded(child: tiles[1]),
                    const SizedBox(width: 10),
                    Expanded(child: tiles[2]),
                  ],
                );
              },
            ),
            if (row.usersAllowedOverride != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.tertiary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.tertiary.withOpacity(.22)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.groups_rounded, color: cs.tertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${l10n.upgrade_requests_users_override}: ${row.usersAllowedOverride}',
                        style: TextStyle(
                          color: cs.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.close_rounded),
                      label: Text(l10n.common_reject),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onMarkPaid,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.payments_rounded),
                      label: const Text('Mark Paid'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMarkUnpaid,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withOpacity(.4)),
                  ),
                  icon: busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.error,
                          ),
                        )
                      : const Icon(Icons.undo_rounded),
                  label: const Text('Mark Unpaid'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeLoadingView extends StatelessWidget {
  const _UpgradeLoadingView();

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
        box(180),
        const SizedBox(height: 16),
        box(230),
        const SizedBox(height: 14),
        box(230),
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
      padding: const EdgeInsets.all(26),
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

class _TinyStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TinyStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  final _UpgradeView current;
  final ValueChanged<_UpgradeView> onChange;

  const _ViewSwitcher({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget seg({
      required IconData icon,
      required String label,
      required _UpgradeView value,
    }) {
      final selected = current == value;
      return Expanded(
        child: InkWell(
          onTap: () => onChange(value),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withOpacity(.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.4)),
      ),
      child: Row(
        children: [
          seg(
            icon: Icons.schedule_rounded,
            label: 'Pending',
            value: _UpgradeView.pending,
          ),
          seg(
            icon: Icons.undo_rounded,
            label: 'Recently Paid',
            value: _UpgradeView.recentlyPaid,
          ),
        ],
      ),
    );
  }
}

/* ========================= Model ========================= */

class UpgradeRequestRow {
  final int id;
  final int aupId;
  final String appName;
  final String slug;
  final String requestedPlanCode;
  final String billingCycle; // MONTHLY | YEARLY | "" (legacy rows)
  final int? usersAllowedOverride;
  final DateTime? requestedAt;

  UpgradeRequestRow({
    required this.id,
    required this.aupId,
    required this.appName,
    required this.slug,
    required this.requestedPlanCode,
    required this.billingCycle,
    required this.usersAllowedOverride,
    required this.requestedAt,
  });

  factory UpgradeRequestRow.fromJson(Map<String, dynamic> j) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return UpgradeRequestRow(
      id: asInt(j['id']),
      aupId: asInt(j['aupId']),
      appName: (j['appName'] ?? '').toString(),
      slug: (j['slug'] ?? '').toString(),
      requestedPlanCode: (j['requestedPlanCode'] ?? '').toString(),
      billingCycle: (j['billingCycle'] ?? '').toString(),
      usersAllowedOverride: j['usersAllowedOverride'] == null
          ? null
          : int.tryParse(j['usersAllowedOverride'].toString()),
      requestedAt: parseDt(j['requestedAt']),
    );
  }
}