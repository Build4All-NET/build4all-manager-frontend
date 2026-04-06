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

class _SuperAdminUpgradeRequestsScreenState
    extends State<SuperAdminUpgradeRequestsScreen> {
  late final Dio _dio;
  late final LicensingApi _api;

  bool _loading = true;
  String? _error;

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
      final res = await _api.pendingUpgradeRequests();
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

  Future<void> _approve(UpgradeRequestRow r) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() => _busyIds.add(r.id));
    try {
      await _api.approveUpgradeRequest(r.id);
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
    final cs = Theme.of(context).colorScheme;
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
                      const SizedBox(height: 16),
                      if (items.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.inbox_rounded,
                          title: _query.trim().isEmpty
                              ? l10n.upgrade_requests_empty
                              : 'No matching requests found',
                          subtitle: _query.trim().isEmpty
                              ? l10n.upgrade_requests_empty_sub
                              : 'Try another keyword for app name, slug, request ID, or plan.',
                        )
                      else
                        ...items.map((r) {
                          final busy = _busyIds.contains(r.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ProUpgradeRequestCard(
                              row: r,
                              busy: busy,
                              onApprove: busy ? null : () => _approve(r),
                              onReject: busy ? null : () => _reject(r),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
      floatingActionButton: !_loading && _error == null
          ? FloatingActionButton.extended(
              onPressed: () => _toast('${items.length} requests visible'),
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
                      'Review, approve, or reject owner plan upgrade requests.',
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
                label: 'Total',
                value: '$total',
                color: cs.primary,
              ),
              _TinyStatChip(
                icon: Icons.visibility_outlined,
                label: 'Shown',
                value: '$filtered',
                color: cs.secondary,
              ),
              _TinyStatChip(
                icon: Icons.schedule_rounded,
                label: 'Pending',
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
              hintText: 'Search by app, slug, request ID, or plan...',
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
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ProUpgradeRequestCard({
    required this.row,
    required this.busy,
    required this.onApprove,
    required this.onReject,
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
                softChip('PENDING', Colors.orange, icon: Icons.schedule_rounded),
                softChip(
                  row.requestedPlanCode.isEmpty ? '—' : row.requestedPlanCode,
                  cs.primary,
                  icon: Icons.workspace_premium_outlined,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              row.slug.trim().isNotEmpty ? row.slug : 'No slug available',
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
                    onPressed: onApprove,
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
                        : const Icon(Icons.check_rounded),
                    label: Text(l10n.common_approve),
                  ),
                ),
              ],
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

/* ========================= Model ========================= */

class UpgradeRequestRow {
  final int id;
  final int aupId;
  final String appName;
  final String slug;
  final String requestedPlanCode;
  final int? usersAllowedOverride;
  final DateTime? requestedAt;

  UpgradeRequestRow({
    required this.id,
    required this.aupId,
    required this.appName,
    required this.slug,
    required this.requestedPlanCode,
    required this.usersAllowedOverride,
    required this.requestedAt,
  });

  factory UpgradeRequestRow.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    DateTime? dt(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    return UpgradeRequestRow(
      id: i(json['id']),
      aupId: i(json['aupId']),
      appName: (json['appName'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      requestedPlanCode: (json['requestedPlanCode'] ?? '').toString(),
      usersAllowedOverride:
          json['usersAllowedOverride'] == null ? null : i(json['usersAllowedOverride']),
      requestedAt: dt(json['requestedAt']),
    );
  }
}