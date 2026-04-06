import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/dashboard/data/services/project_api.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

/// Orders screen for a specific owner app (ownerProjectId).
/// Open this from OwnerAppsInProjectScreen when the super admin taps an app.
class OwnerAppOrdersScreen extends StatefulWidget {
  final int ownerProjectId;
  final String appName;

  const OwnerAppOrdersScreen({
    super.key,
    required this.ownerProjectId,
    required this.appName,
  });

  @override
  State<OwnerAppOrdersScreen> createState() => _OwnerAppOrdersScreenState();
}

class _OwnerAppOrdersScreenState extends State<OwnerAppOrdersScreen> {
  late final Dio _dio;
  late final ProjectApi _api;

  bool _loading = true;
  String? _error;

  List<SuperAdminOrderHeaderRow> _orders = const [];

  DateTimeRange? _range;
  int? _quickDaysSelected; // 7 / 30 / null
  String? _statusFilter; // null => ALL

  @override
  void initState() {
    super.initState();
    _dio = DioClient.ensure();
    _api = ProjectApi(_dio);
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
      final res = await _api.ownerAppOrders(widget.ownerProjectId);
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final items = list.map(SuperAdminOrderHeaderRow.fromJson).toList();

      setState(() {
        _orders = items;
        _loading = false;
      });
      } catch (e) {
      final msg = ApiErrorHandler.message(e);
      setState(() {
        _error = msg;
        _loading = false;
      });
      _toast(msg, error: true);
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
    );

    if (picked != null && mounted) {
      setState(() {
        _range = picked;
        _quickDaysSelected = null;
      });
    }
  }

  void _quickRange(int days) {
    final now = DateTime.now();
    setState(() {
      _quickDaysSelected = days;
      _range = DateTimeRange(
        start: now.subtract(Duration(days: days)),
        end: now,
      );
    });
  }

  void _clearRange() {
    setState(() {
      _range = null;
      _quickDaysSelected = null;
    });
  }

  List<SuperAdminOrderHeaderRow> get _statusFiltered {
    if (_statusFilter == null || _statusFilter == 'ALL') return _orders;
    final f = _statusFilter!.toUpperCase();
    return _orders.where((o) => o.status.toUpperCase() == f).toList();
  }

  List<SuperAdminOrderHeaderRow> get _rangeFiltered {
    if (_range == null) return _statusFiltered;

    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    final start = day(_range!.start);
    final end = day(_range!.end);

    return _statusFiltered.where((o) {
      final dt = o.orderDate;
      if (dt == null) return false;
      final x = day(dt.toLocal());
      return !x.isBefore(start) && !x.isAfter(end);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    const spacing = 12.0;

    final filteredOrders = _rangeFiltered;
    final stats = computeOrdersStats(filteredOrders);

    return Scaffold(
      // let global theme decide background, no manual "black"
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
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
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      OwnerAppOrdersAnalyticsHeader(
                        stats: stats,
                        range: _range,
                        quickDaysSelected: _quickDaysSelected,
                        onPickRange: () => _pickRange(context),
                        onQuick7: () => _quickRange(7),
                        onQuick30: () => _quickRange(30),
                        onClear: _clearRange,
                      ),
                      const SizedBox(height: 16),
                      StatusFilterChips(
                        selected: _statusFilter,
                        onChanged: (value) {
                          setState(() {
                            _statusFilter =
                                (value == 'ALL') ? null : value.toUpperCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (filteredOrders.isEmpty)
                        _EmptyState(
                          title: l10n.noOrdersTitle,
                          subtitle: l10n.noOrdersSubtitle,
                        ),
                      ...filteredOrders.map(
                        (o) => Padding(
                          padding: const EdgeInsets.only(bottom: spacing),
                          child: SuperAdminOrderCard(
                            row: o,
                            onTap: () {
                              // TODO: push a details screen when you create it.
                             AppToast.info(
  context,
  '${l10n.orderLabel} ${((o.orderCode ?? '').trim().isNotEmpty) ? o.orderCode : '#${o.id}'}',
);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

/// Simple inline error widget used inside the screen.
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
            child: Text(l10n.retryLabel),
          ),
        ],
      ),
    );
  }
}

/* ========================= Models ========================= */

class SuperAdminOrderHeaderRow {
  final int id;
  final String? orderCode;     // ✅ NEW
  final int? orderSeq;         // ✅ NEW

  final DateTime? orderDate;
  final double totalPrice;
  final String status;
  final String statusUi;
  final int itemsCount;
  final bool fullyPaid;
  final PaymentSummary payment;

  SuperAdminOrderHeaderRow({
    required this.id,
    required this.orderCode,
    required this.orderSeq,
    required this.orderDate,
    required this.totalPrice,
    required this.status,
    required this.statusUi,
    required this.itemsCount,
    required this.fullyPaid,
    required this.payment,
  });

  factory SuperAdminOrderHeaderRow.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    }

    double d(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return SuperAdminOrderHeaderRow(
      id: (json['id'] as num).toInt(),
      orderCode: json['orderCode']?.toString(),              //  NEW
      orderSeq: (json['orderSeq'] as num?)?.toInt(),         //  NEW
      orderDate: parseDate(json['orderDate']),
      totalPrice: d(json['totalPrice']),
      status: (json['status'] ?? '').toString(),
      statusUi: (json['statusUi'] ?? '').toString(),
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      fullyPaid: json['fullyPaid'] == true,
      payment: PaymentSummary.fromJson(
        (json['payment'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
class PaymentSummary {
  final double orderTotal;
  final double paidAmount;
  final double remainingAmount;
  final String paymentState;

  PaymentSummary({
    required this.orderTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentState,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    double d(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return PaymentSummary(
      orderTotal: d(json['orderTotal']),
      paidAmount: d(json['paidAmount']),
      remainingAmount: d(json['remainingAmount']),
      paymentState: (json['paymentState'] ?? '').toString(),
    );
  }
}

/* ========================= Stats & Analytics Header ========================= */

class OrdersStats {
  final int ordersCount;
  final double grossSales;
  final double paidRevenue;
  final double outstanding;
  final double avgOrderValue;
  final int fullyPaidCount;
  final Map<String, int> statusCounts;
  final List<_RevenueDay> last7Days;

  const OrdersStats({
    required this.ordersCount,
    required this.grossSales,
    required this.paidRevenue,
    required this.outstanding,
    required this.avgOrderValue,
    required this.fullyPaidCount,
    required this.statusCounts,
    required this.last7Days,
  });

  double get fullyPaidRate =>
      ordersCount == 0 ? 0 : (fullyPaidCount / ordersCount).clamp(0, 1);
}

class _RevenueDay {
  final DateTime day;
  final double revenue;
  const _RevenueDay(this.day, this.revenue);
}

OrdersStats computeOrdersStats(List<SuperAdminOrderHeaderRow> orders) {
  final statusCounts = <String, int>{};

  double gross = 0;
  double paid = 0;
  double outstanding = 0;
  int fullyPaidCount = 0;

  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final now = DateTime.now();
  final days = List.generate(7, (idx) {
    final d = now.subtract(Duration(days: 6 - idx));
    return day(d);
  });
  final revByDay = {for (final d in days) d: 0.0};

  for (final o in orders) {
    final total =
        (o.payment.orderTotal <= 0) ? o.totalPrice : o.payment.orderTotal;

    gross += total;

    final st = o.status.toUpperCase();
    statusCounts[st] = (statusCounts[st] ?? 0) + 1;

    paid += o.payment.paidAmount;

    final rem = (o.payment.remainingAmount > 0)
        ? o.payment.remainingAmount
        : (total - o.payment.paidAmount);
    outstanding += rem < 0 ? 0 : rem;

    final fp = o.fullyPaid || o.payment.paymentState.toUpperCase() == 'PAID';
    if (fp) fullyPaidCount++;

    final dt = o.orderDate;
    if (dt != null) {
      final dk = day(dt.toLocal());
      if (revByDay.containsKey(dk)) {
        revByDay[dk] = (revByDay[dk] ?? 0) + o.payment.paidAmount;
      }
    }
  }

  final count = orders.length;
  final avg = count == 0 ? 0.0 : gross / count;
  final last7 = days.map((d) => _RevenueDay(d, revByDay[d] ?? 0)).toList();

  return OrdersStats(
    ordersCount: count,
    grossSales: gross,
    paidRevenue: paid,
    outstanding: outstanding,
    avgOrderValue: avg,
    fullyPaidCount: fullyPaidCount,
    statusCounts: statusCounts,
    last7Days: last7,
  );
}

class OwnerAppOrdersAnalyticsHeader extends StatelessWidget {
  final OrdersStats stats;
  final DateTimeRange? range;
  final int? quickDaysSelected;

  final VoidCallback? onPickRange;
  final VoidCallback? onQuick7;
  final VoidCallback? onQuick30;
  final VoidCallback? onClear;

  const OwnerAppOrdersAnalyticsHeader({
    super.key,
    required this.stats,
    this.range,
    this.quickDaysSelected,
    this.onPickRange,
    this.onQuick7,
    this.onQuick30,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    const spacing = 8.0;

    bool quickSelected(int d) => quickDaysSelected == d;

    Widget quickChip(String label, int days, VoidCallback? onTap) {
      final sel = quickSelected(days);
      return ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => onTap?.call(),
        selectedColor: cs.primary.withOpacity(0.16),
        backgroundColor: cs.surface,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: sel ? cs.primary : cs.outline,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    Widget kpi(String title, String value, IconData icon) {
      return Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 18),
            const SizedBox(height: spacing),
            Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: cs.outline,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: spacing / 2),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    final maxRev = stats.last7Days.fold<double>(
      0.0,
      (m, e) => e.revenue > m ? e.revenue : m,
    );

    String fmtRange(DateTimeRange? r) {
      if (r == null) return l10n.allTimeLabel;
      String two(int v) => v.toString().padLeft(2, '0');
      final a = r.start.toLocal();
      final b = r.end.toLocal();
      return '${a.year}-${two(a.month)}-${two(a.day)} → '
          '${b.year}-${two(b.month)}-${two(b.day)}';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + date picker
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dashboardLabel,
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onPickRange != null)
                TextButton.icon(
                  onPressed: onPickRange,
                  icon: Icon(Icons.date_range, size: 18, color: cs.outline),
                  label: Text(
                    fmtRange(range),
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Quick range chips + clear
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              quickChip(l10n.last7DaysLabel, 7, onQuick7),
              quickChip(l10n.last30DaysLabel, 30, onQuick30),
              ActionChip(
                label: Text(l10n.clearLabel),
                onPressed: onClear,
                backgroundColor: cs.surface,
                labelStyle: textTheme.bodySmall?.copyWith(
                  color: cs.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // KPIs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                kpi(l10n.ordersLabel, '${stats.ordersCount}',
                    Icons.receipt_long),
                const SizedBox(width: 8),
                kpi(l10n.grossSalesLabel, stats.grossSales.toStringAsFixed(2),
                    Icons.trending_up),
                const SizedBox(width: 8),
                kpi(l10n.paidLabel, stats.paidRevenue.toStringAsFixed(2),
                    Icons.payments),
                const SizedBox(width: 8),
                kpi(l10n.outstandingLabel, stats.outstanding.toStringAsFixed(2),
                    Icons.hourglass_bottom),
                const SizedBox(width: 8),
                kpi(l10n.avgOrderLabel, stats.avgOrderValue.toStringAsFixed(2),
                    Icons.calculate),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Fully paid rate
          Row(
            children: [
              Text(
                '${l10n.fullyPaidRateLabel} ${(stats.fullyPaidRate * 100).toStringAsFixed(0)}%',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.outline,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${stats.fullyPaidCount}/${stats.ordersCount}',
                style: textTheme.bodySmall?.copyWith(
                  color: cs.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stats.fullyPaidRate,
              minHeight: 8,
              backgroundColor: cs.outlineVariant.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),

          const SizedBox(height: 12),

          // Status breakdown
          Text(
            l10n.statusBreakdownLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: stats.statusCounts.entries.map((e) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing,
                  vertical: spacing / 2,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
                ),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Revenue last 7 days
          Text(
            l10n.paidRevenueLast7DaysLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stats.last7Days.map((p) {
              final h = maxRev <= 0
                  ? 6.0
                  : (60.0 * (p.revenue / maxRev)).clamp(6.0, 60.0);
              final label = '${p.day.month}/${p.day.day}';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/* ========================= Filters & Cards ========================= */

class StatusFilterChips extends StatelessWidget {
  final String? selected; // null => ALL
  final ValueChanged<String> onChanged;

  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;
    const spacing = 8.0;

    final sel = (selected ?? 'ALL').toUpperCase();

    Widget chip(String label, String value) {
      final isSel = sel == value;
      return ChoiceChip(
        label: Text(label),
        selected: isSel,
        onSelected: (_) => onChanged(value),
        selectedColor: cs.primary.withOpacity(0.16),
        backgroundColor: cs.surface,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: isSel ? cs.primary : cs.onSurfaceVariant,
          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
        ),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        chip(l10n.filterAllLabel, 'ALL'),
        chip(l10n.filterPendingLabel, 'PENDING'),
        chip(l10n.filterCompletedLabel, 'COMPLETED'),
        chip(l10n.filterCanceledLabel, 'CANCELED'),
        chip(l10n.filterRejectedLabel, 'REJECTED'),
        chip(l10n.filterRefundedLabel, 'REFUNDED'),
      ],
    );
  }
}

class SuperAdminOrderCard extends StatelessWidget {
  final SuperAdminOrderHeaderRow row;
  final VoidCallback onTap;

  const SuperAdminOrderCard({
    super.key,
    required this.row,
    required this.onTap,
  });

  Color _statusColor(ColorScheme cs) {
    final s = row.status.toUpperCase();
    if (s == 'COMPLETED') return cs.primary;
    if (s == 'CANCELED' || s == 'REJECTED' || s == 'REFUNDED') {
      return cs.error;
    }
    return cs.outline;
  }

  Color _paymentColor(ColorScheme cs) {
    final p = row.payment.paymentState.toUpperCase();
    if (p == 'PAID') return cs.primary;
    if (p == 'PARTIAL') return cs.tertiary;
    if (p == 'UNPAID') return cs.error;
    return cs.outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = AppLocalizations.of(context)!;

    final total =
        (row.payment.orderTotal <= 0) ? row.totalPrice : row.payment.orderTotal;
    final paid = row.payment.paidAmount;
    final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

final displayCode = (row.orderCode ?? '').trim();
final title = displayCode.isNotEmpty
    ? '${l10n.orderLabel} $displayCode'
    : '${l10n.orderLabel} #${row.id}';

    String fmtDate(DateTime? dt) {
      if (dt == null) return '—';
      final d = dt.toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)}  '
          '${two(d.hour)}:${two(d.minute)}';
    }

    Widget badge(String text, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                badge(
                  row.statusUi.isNotEmpty ? row.statusUi : row.status,
                  _statusColor(cs),
                ),
                const SizedBox(width: 6),
                badge(
                  row.payment.paymentState,
                  _paymentColor(cs),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: cs.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    fmtDate(row.orderDate),
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${l10n.itemsLabel}: ${row.itemsCount}',
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: cs.outlineVariant.withOpacity(0.25),
                valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.totalLabel}: ${total.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!row.fullyPaid)
                  Text(
                    '${l10n.remainingLabel}: ${row.payment.remainingAmount.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    l10n.fullyPaidShortLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
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

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: cs.outline),
          const SizedBox(height: 8),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: cs.outline,
            ),
          ),
        ],
      ),
    );
  }
}
