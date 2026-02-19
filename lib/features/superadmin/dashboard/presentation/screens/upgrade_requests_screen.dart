import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
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

      // newest first (if requestedAt exists)
      items.sort((a, b) => (b.requestedAt ?? DateTime(1970))
          .compareTo(a.requestedAt ?? DateTime(1970)));

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      final msg = e.toString();
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
      setState(() => _items.removeWhere((x) => x.id == r.id));
      _toast(l10n.upgrade_requests_approve_success);
    } catch (e) {
      _toast(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busyIds.remove(r.id));
    }
  }

  Future<void> _reject(UpgradeRequestRow r) async {
    final l10n = AppLocalizations.of(context)!;
    final note = await _showRejectDialog();

    if (note == null) return; // canceled

    setState(() => _busyIds.add(r.id));
    try {
      await _api.rejectUpgradeRequest(r.id, note: note.trim().isEmpty ? null : note.trim());
      setState(() => _items.removeWhere((x) => x.id == r.id));
      _toast(l10n.upgrade_requests_reject_success);
    } catch (e) {
      _toast(e.toString(), error: true);
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
          title: Text(l10n.upgrade_requests_reject_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.upgrade_requests_reject_hint,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: c,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.upgrade_requests_note_optional,
                  border: const OutlineInputBorder(),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

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
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _InlineError(
                        message: _error!,
                        onRetry: _load,
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Icon(Icons.inbox_rounded, size: 44, color: cs.outline),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              l10n.upgrade_requests_empty,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              l10n.upgrade_requests_empty_sub,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = _items[i];
                          final busy = _busyIds.contains(r.id);

                          return _RequestCard(
                            row: r,
                            busy: busy,
                            onApprove: busy ? null : () => _approve(r),
                            onReject: busy ? null : () => _reject(r),
                          );
                        },
                      ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final UpgradeRequestRow row;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RequestCard({
    required this.row,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    String fmtDate(DateTime? dt) {
      if (dt == null) return '—';
      final d = dt.toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
    }

    Widget chip(String text, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(.28)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.upgrade_requests_request} #${row.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                chip(row.requestedPlanCode.isEmpty ? '—' : row.requestedPlanCode,
                    cs.primary),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip('${l10n.upgrade_requests_aup}: ${row.aupId}', cs.outline),
                chip('${l10n.upgrade_requests_requested_at}: ${fmtDate(row.requestedAt)}',
                    cs.outline),
                if (row.usersAllowedOverride != null)
                  chip(
                    '${l10n.upgrade_requests_users_override}: ${row.usersAllowedOverride}',
                    cs.tertiary,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
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
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
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

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(l10n.common_retry),
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
  final String requestedPlanCode;
  final int? usersAllowedOverride;
  final DateTime? requestedAt;

  UpgradeRequestRow({
    required this.id,
    required this.aupId,
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
      requestedPlanCode: (json['requestedPlanCode'] ?? '').toString(),
      usersAllowedOverride: json['usersAllowedOverride'] == null
          ? null
          : i(json['usersAllowedOverride']),
      requestedAt: dt(json['requestedAt']),
    );
  }
}
