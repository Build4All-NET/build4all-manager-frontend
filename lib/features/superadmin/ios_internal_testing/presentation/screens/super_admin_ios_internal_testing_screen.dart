import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/presentation/widgets/ios_internal_testing_status_chip.dart';

import '../../data/models/super_admin_ios_internal_testing_request_model.dart';
import '../../data/services/super_admin_ios_internal_testing_api.dart';
import '../bloc/super_admin_ios_internal_testing_bloc.dart';
import '../bloc/super_admin_ios_internal_testing_event.dart';
import '../bloc/super_admin_ios_internal_testing_state.dart';

// ── Screen entry ──────────────────────────────────────────────────────────────

class SuperAdminIosInternalTestingScreen extends StatelessWidget {
  final Dio dio;

  const SuperAdminIosInternalTestingScreen({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuperAdminIosInternalTestingBloc(
        api: SuperAdminIosInternalTestingApi(dio),
      )..add(const SuperAdminIosInternalTestingStarted()),
      child: const _View(),
    );
  }
}

// ── Main view ──────────────────────────────────────────────────────────────────

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _statuses = [
    'ALL',
    'REQUESTED',
    'PROCESSING',
    'INVITED_TO_APPLE_TEAM',
    'WAITING_OWNER_ACCEPTANCE',
    'ADDING_TO_INTERNAL_TESTING',
    'FAILED',
    'READY',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      context.read<SuperAdminIosInternalTestingBloc>().add(
            SuperAdminIosInternalTestingSearchChanged(_searchCtrl.text),
          );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchCtrl.clear();
    context.read<SuperAdminIosInternalTestingBloc>()
      ..add(const SuperAdminIosInternalTestingSearchChanged(''))
      ..add(const SuperAdminIosInternalTestingStatusChanged('ALL'));
  }

  bool _hasActiveFilters(SuperAdminIosInternalTestingState state) =>
      state.searchQuery.isNotEmpty || state.selectedStatus != 'ALL';

  void _openDetail(
    BuildContext ctx,
    SuperAdminIosInternalTestingRequestModel request,
    SuperAdminIosInternalTestingBloc bloc,
  ) {
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _RequestDetailPage(request: request),
        ),
      ),
    );
  }

  String _noticeText(
    AppLocalizations l10n,
    SuperAdminIosInternalTestingState state,
  ) {
    switch (state.notice) {
      case SuperAdminIosInternalTestingNotice.processSuccess:
        return l10n.super_ios_internal_testing_process_success;
      case SuperAdminIosInternalTestingNotice.syncSuccess:
        return l10n.super_ios_internal_testing_sync_success;
      case SuperAdminIosInternalTestingNotice.noSyncableVisible:
        return l10n.super_ios_internal_testing_no_syncable_visible;
      case SuperAdminIosInternalTestingNotice.syncAllFinished:
        return l10n.super_ios_internal_testing_sync_all_finished(
          state.syncAllUpdatedCount,
        );
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<SuperAdminIosInternalTestingBloc,
        SuperAdminIosInternalTestingState>(
      listenWhen: (p, c) =>
          p.error != c.error ||
          p.notice != c.notice ||
          p.syncAllUpdatedCount != c.syncAllUpdatedCount,
      listener: (ctx, state) {
        if ((state.error ?? '').trim().isNotEmpty) {
          AppToast.error(ctx, state.error!);
          ctx.read<SuperAdminIosInternalTestingBloc>().add(
                const SuperAdminIosInternalTestingErrorCleared(),
              );
        }
        if (state.notice != null) {
          AppToast.success(ctx, _noticeText(l10n, state));
          ctx.read<SuperAdminIosInternalTestingBloc>().add(
                const SuperAdminIosInternalTestingNoticeCleared(),
              );
        }
      },
      builder: (ctx, state) {
        final bloc = ctx.read<SuperAdminIosInternalTestingBloc>();
        final isInitialLoad = state.loading && state.requests.isEmpty;
        final items = state.filteredRequests;

        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    bloc.add(const SuperAdminIosInternalTestingRefreshed());
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _PageHeader(
                        totalCount: state.totalCount,
                        failedCount: state.failedCount,
                        readyCount: state.readyCount,
                        acting: state.acting,
                        loading: isInitialLoad,
                        onSyncAll: () => bloc.add(
                          const SuperAdminIosInternalTestingSyncAllPressed(),
                        ),
                        onRefresh: () => bloc.add(
                          const SuperAdminIosInternalTestingRefreshed(),
                        ),
                        l10n: l10n,
                      ),
                      const SizedBox(height: 14),
                      _FilterBar(
                        searchCtrl: _searchCtrl,
                        selectedStatus: state.selectedStatus,
                        statuses: _statuses,
                        hasActive: _hasActiveFilters(state),
                        onStatusChanged: (s) => bloc.add(
                          SuperAdminIosInternalTestingStatusChanged(s),
                        ),
                        onReset: _resetFilters,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 14),
                      if (isInitialLoad)
                        const _SkeletonList()
                      else if (state.requests.isEmpty)
                        _EmptyState(l10n: l10n)
                      else if (items.isEmpty)
                        _FilteredEmpty(
                          onReset: _resetFilters,
                          l10n: l10n,
                        )
                      else
                        Column(
                          children: items
                              .map(
                                (r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _CompactRequestCard(
                                    request: r,
                                    onTap: () => _openDetail(ctx, r, bloc),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Page header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final int totalCount;
  final int failedCount;
  final int readyCount;
  final bool acting;
  final bool loading;
  final VoidCallback onSyncAll;
  final VoidCallback onRefresh;
  final AppLocalizations l10n;

  const _PageHeader({
    required this.totalCount,
    required this.failedCount,
    required this.readyCount,
    required this.acting,
    required this.loading,
    required this.onSyncAll,
    required this.onRefresh,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.super_nav_ios_internal_testing,
                      style: tt.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage iOS TestFlight testers across all projects.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(.60),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: acting ? null : onSyncAll,
                    icon: acting
                        ? SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: cs.onSecondaryContainer,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      l10n.super_ios_internal_testing_sync_all_visible_pending,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: loading ? null : onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: l10n.super_ios_internal_testing_refresh,
                    style: IconButton.styleFrom(
                      backgroundColor:
                          cs.surfaceContainerHighest.withOpacity(.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _StatPill(
                icon: Icons.layers_rounded,
                label: l10n.super_ios_internal_testing_total,
                value: loading ? '—' : totalCount.toString(),
                color: cs.primary,
                cs: cs,
                tt: tt,
              ),
              _StatPill(
                icon: Icons.error_outline_rounded,
                label: l10n.super_ios_internal_testing_failed,
                value: loading ? '—' : failedCount.toString(),
                color: failedCount > 0 ? cs.error : cs.outline,
                cs: cs,
                tt: tt,
              ),
              _StatPill(
                icon: Icons.verified_rounded,
                label: l10n.super_ios_internal_testing_ready,
                value: loading ? '—' : readyCount.toString(),
                color: const Color(0xFF16A34A),
                cs: cs,
                tt: tt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;
  final TextTheme tt;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$value ',
            style: tt.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: color.withOpacity(.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String selectedStatus;
  final List<String> statuses;
  final bool hasActive;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onReset;
  final AppLocalizations l10n;

  const _FilterBar({
    required this.searchCtrl,
    required this.selectedStatus,
    required this.statuses,
    required this.hasActive,
    required this.onStatusChanged,
    required this.onReset,
    required this.l10n,
  });

  String _chipLabel(String value) {
    switch (value.toUpperCase()) {
      case 'ALL':
        return l10n.super_ios_internal_testing_status_all;
      case 'REQUESTED':
        return l10n.super_ios_internal_testing_status_requested;
      case 'PROCESSING':
        return l10n.super_ios_internal_testing_status_processing;
      case 'INVITED_TO_APPLE_TEAM':
        return l10n.super_ios_internal_testing_status_invitation_sent;
      case 'WAITING_OWNER_ACCEPTANCE':
        return l10n.super_ios_internal_testing_status_waiting_acceptance;
      case 'ADDING_TO_INTERNAL_TESTING':
        return l10n.super_ios_internal_testing_status_adding;
      case 'FAILED':
        return l10n.super_ios_internal_testing_status_failed;
      case 'READY':
        return l10n.super_ios_internal_testing_status_ready;
      case 'CANCELLED':
        return l10n.super_ios_internal_testing_status_cancelled;
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: l10n.super_ios_internal_testing_search_hint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: searchCtrl.clear,
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...statuses.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onStatusChanged(s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: s == selectedStatus
                              ? cs.primary
                              : cs.surfaceContainerHighest.withOpacity(.55),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: s == selectedStatus
                                ? cs.primary
                                : cs.outlineVariant.withOpacity(.40),
                          ),
                        ),
                        child: Text(
                          _chipLabel(s),
                          style: tt.labelSmall?.copyWith(
                            color: s == selectedStatus
                                ? cs.onPrimary
                                : cs.onSurface.withOpacity(.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasActive)
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
                    label: Text(l10n.common_clear),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact list card ────────────────────────────────────────────────────────

class _CompactRequestCard extends StatelessWidget {
  final SuperAdminIosInternalTestingRequestModel request;
  final VoidCallback onTap;

  const _CompactRequestCard({
    required this.request,
    required this.onTap,
  });

  String _appInitial() {
    final name = request.appNameSnapshot.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final appName = request.appNameSnapshot.trim().isNotEmpty
        ? request.appNameSnapshot
        : 'AUP ${request.ownerProjectLinkId}';
    final bundleId = request.bundleIdSnapshot.trim();
    final fullName = request.fullName;
    final date = _formatDate(request.updatedAt ?? request.createdAt);

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: request.isFailed
                  ? cs.error.withOpacity(.30)
                  : cs.outlineVariant.withOpacity(.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _appInitial(),
                    style: tt.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: tt.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bundleId.isNotEmpty)
                      Text(
                        bundleId,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.50),
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      fullName.isNotEmpty
                          ? '$fullName · ${request.appleEmail}'
                          : request.appleEmail,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.60),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IosInternalTestingStatusChip(
                    status: request.status,
                    compact: true,
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.38),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withOpacity(.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Request detail page ───────────────────────────────────────────────────

class _RequestDetailPage extends StatelessWidget {
  final SuperAdminIosInternalTestingRequestModel request;

  const _RequestDetailPage({required this.request});

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min';
  }

  String _appInitial() {
    final name = request.appNameSnapshot.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final appName = request.appNameSnapshot.trim().isNotEmpty
        ? request.appNameSnapshot
        : l10n.super_ios_internal_testing_unnamed_app;
    final fullName = request.fullName;

    return BlocBuilder<SuperAdminIosInternalTestingBloc,
        SuperAdminIosInternalTestingState>(
      builder: (context, state) {
        final isActing =
            state.acting && state.actionRequestId == request.id;

        void onProcess() {
          context.read<SuperAdminIosInternalTestingBloc>().add(
                SuperAdminIosInternalTestingProcessPressed(request.id),
              );
        }

        void onSync() {
          context.read<SuperAdminIosInternalTestingBloc>().add(
                SuperAdminIosInternalTestingSyncPressed(request.id),
              );
        }

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: Text(
              appName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // ── Tester identity ────────────────────────────────────────────
              _DetailSection(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _appInitial(),
                          style: tt.titleLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (request.bundleIdSnapshot.trim().isNotEmpty)
                            Text(
                              request.bundleIdSnapshot,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withOpacity(.55),
                                fontFamily: 'monospace',
                              ),
                            ),
                          const SizedBox(height: 6),
                          IosInternalTestingStatusChip(
                            status: request.status,
                            compact: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Tester info ──────────────────────────────────────────────
              _DetailSection(
                title: 'Tester',
                child: Column(
                  children: [
                    if (fullName.isNotEmpty)
                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Name',
                        value: fullName,
                        cs: cs,
                        tt: tt,
                      ),
                    _DetailRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Apple Email',
                      value: request.appleEmail,
                      cs: cs,
                      tt: tt,
                      copyable: true,
                    ),
                    _DetailRow(
                      icon: Icons.link_rounded,
                      label: l10n.super_ios_internal_testing_aup_label,
                      value: 'AUP ${request.ownerProjectLinkId}',
                      cs: cs,
                      tt: tt,
                    ),
                    _DetailRow(
                      icon: Icons.tag_rounded,
                      label: l10n.super_ios_internal_testing_request_label,
                      value: '#${request.id}',
                      cs: cs,
                      tt: tt,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Error ──────────────────────────────────────────────────────
              if ((request.lastError ?? '').trim().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.error.withOpacity(.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.error.withOpacity(.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 18, color: cs.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          request.lastError!,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.error,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Timeline ────────────────────────────────────────────────
              _DetailSection(
                title: 'Timeline',
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Requested',
                      value: _formatDateTime(
                          request.requestedAt ?? request.createdAt),
                      cs: cs,
                      tt: tt,
                    ),
                    if (request.processedAt != null)
                      _DetailRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Processed',
                        value: _formatDateTime(request.processedAt),
                        cs: cs,
                        tt: tt,
                      ),
                    if (request.acceptedAt != null)
                      _DetailRow(
                        icon: Icons.verified_outlined,
                        label: 'Accepted',
                        value: _formatDateTime(request.acceptedAt),
                        cs: cs,
                        tt: tt,
                      ),
                    if (request.readyAt != null)
                      _DetailRow(
                        icon: Icons.rocket_launch_outlined,
                        label: 'Ready',
                        value: _formatDateTime(request.readyAt),
                        cs: cs,
                        tt: tt,
                      ),
                    if (request.updatedAt != null)
                      _DetailRow(
                        icon: Icons.update_rounded,
                        label: 'Last updated',
                        value: _formatDateTime(request.updatedAt),
                        cs: cs,
                        tt: tt,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Technical IDs ─────────────────────────────────────────────
              if ((request.appleUserId ?? '').isNotEmpty ||
                  (request.appleInvitationId ?? '').isNotEmpty) ...[
                _ExpandableSection(
                  title: 'Technical Details',
                  cs: cs,
                  tt: tt,
                  children: [
                    _DetailRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'Owner ID',
                      value: request.ownerId.toString(),
                      cs: cs,
                      tt: tt,
                    ),
                    if ((request.appleUserId ?? '').isNotEmpty)
                      _DetailRow(
                        icon: Icons.person_pin_rounded,
                        label: 'Apple User ID',
                        value: request.appleUserId!,
                        cs: cs,
                        tt: tt,
                        mono: true,
                        copyable: true,
                      ),
                    if ((request.appleInvitationId ?? '').isNotEmpty)
                      _DetailRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Invitation ID',
                        value: request.appleInvitationId!,
                        cs: cs,
                        tt: tt,
                        mono: true,
                        copyable: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Actions ───────────────────────────────────────────────────
              _DetailSection(
                title: 'Actions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: isActing ? null : onProcess,
                      icon: isActing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_circle_outline_rounded),
                      label: Text(l10n.super_ios_internal_testing_process),
                    ),
                    if (request.isSyncable) ...[
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: isActing ? null : onSync,
                        icon: isActing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onSecondaryContainer,
                                ),
                              )
                            : const Icon(Icons.sync_rounded),
                        label: Text(l10n.super_ios_internal_testing_sync),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Detail section wrapper ──────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final String? title;
  final Widget child;

  const _DetailSection({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: tt.labelMedium?.copyWith(
                color: cs.onSurface.withOpacity(.48),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme tt;
  final bool mono;
  final bool copyable;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
    this.mono = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(.38)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.46),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 1),
                GestureDetector(
                  onLongPress: copyable
                      ? () {
                          Clipboard.setData(ClipboardData(text: value));
                          AppToast.success(context, 'Copied');
                        }
                      : null,
                  child: Text(
                    value,
                    style: tt.bodyMedium?.copyWith(
                      fontFamily: mono ? 'monospace' : null,
                      color: cs.onSurface.withOpacity(.84),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final ColorScheme cs;
  final TextTheme tt;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    required this.cs,
    required this.tt,
    required this.children,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final tt = widget.tt;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.55)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.code_rounded,
                    size: 16,
                    color: cs.onSurface.withOpacity(.40),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurface.withOpacity(.50),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: cs.onSurface.withOpacity(.38),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
                height: 1,
                color: cs.outlineVariant.withOpacity(.38)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(children: widget.children),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty states ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.50)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.science_outlined,
              size: 44,
              color: cs.primary.withOpacity(.60),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.super_ios_internal_testing_empty_state,
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FilteredEmpty extends StatelessWidget {
  final VoidCallback onReset;
  final AppLocalizations l10n;

  const _FilteredEmpty({required this.onReset, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.50)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: cs.onSurface.withOpacity(.25),
          ),
          const SizedBox(height: 12),
          Text(
            'No records match your filters',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.60),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
            label: Text(l10n.common_clear),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton loader ──────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _SkeletonCard(),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final base = cs.surfaceContainerHighest
            .withOpacity(0.45 + 0.20 * _anim.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(.38)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bone(width: 110, height: 13, base: base),
                    const SizedBox(height: 5),
                    _Bone(
                        width: 170,
                        height: 11,
                        base: base.withOpacity(base.opacity * 0.75)),
                    const SizedBox(height: 5),
                    _Bone(
                        width: 200,
                        height: 10,
                        base: base.withOpacity(base.opacity * 0.60)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Bone(width: 68, height: 24, base: base, radius: 999),
            ],
          ),
        );
      },
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  final Color base;
  final double radius;

  const _Bone({
    required this.width,
    required this.height,
    required this.base,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
