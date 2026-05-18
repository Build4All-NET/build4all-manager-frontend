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

// ─── Entry ────────────────────────────────────────────────────────────────────

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

// ─── Main view ────────────────────────────────────────────────────────────────

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _searchCtrl = TextEditingController();

  static const _statuses = [
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
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    context.read<SuperAdminIosInternalTestingBloc>().add(
          SuperAdminIosInternalTestingSearchChanged(_searchCtrl.text),
        );
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    _searchCtrl.clear();
    context.read<SuperAdminIosInternalTestingBloc>()
      ..add(const SuperAdminIosInternalTestingSearchChanged(''))
      ..add(const SuperAdminIosInternalTestingStatusChanged('ALL'));
  }

  bool _hasActive(SuperAdminIosInternalTestingState s) =>
      s.searchQuery.isNotEmpty || s.selectedStatus != 'ALL';

  void _openDetail(
    BuildContext ctx,
    SuperAdminIosInternalTestingRequestModel r,
    SuperAdminIosInternalTestingBloc bloc,
  ) {
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: _DetailPage(request: r),
        ),
      ),
    );
  }

  String _noticeMsg(
    AppLocalizations l10n,
    SuperAdminIosInternalTestingState s,
  ) {
    switch (s.notice) {
      case SuperAdminIosInternalTestingNotice.processSuccess:
        return l10n.super_ios_internal_testing_process_success;
      case SuperAdminIosInternalTestingNotice.syncSuccess:
        return l10n.super_ios_internal_testing_sync_success;
      case SuperAdminIosInternalTestingNotice.noSyncableVisible:
        return l10n.super_ios_internal_testing_no_syncable_visible;
      case SuperAdminIosInternalTestingNotice.syncAllFinished:
        return l10n.super_ios_internal_testing_sync_all_finished(
            s.syncAllUpdatedCount);
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SuperAdminIosInternalTestingBloc,
        SuperAdminIosInternalTestingState>(
      listenWhen: (p, c) => p.error != c.error || p.notice != c.notice,
      listener: (ctx, state) {
        if ((state.error ?? '').trim().isNotEmpty) {
          AppToast.error(ctx, state.error!);
          ctx
              .read<SuperAdminIosInternalTestingBloc>()
              .add(const SuperAdminIosInternalTestingErrorCleared());
        }
        if (state.notice != null) {
          AppToast.success(ctx, _noticeMsg(l10n, state));
          ctx
              .read<SuperAdminIosInternalTestingBloc>()
              .add(const SuperAdminIosInternalTestingNoticeCleared());
        }
      },
      builder: (ctx, state) {
        final bloc = ctx.read<SuperAdminIosInternalTestingBloc>();
        final cs = Theme.of(ctx).colorScheme;
        final isInitialLoad = state.loading && state.requests.isEmpty;
        final items = state.filteredRequests;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: Text(l10n.super_nav_ios_internal_testing),
            scrolledUnderElevation: 1,
            actions: [
              if (!isInitialLoad) ...
                [
                  FilledButton.tonalIcon(
                    onPressed: state.acting
                        ? null
                        : () => bloc.add(
                              const SuperAdminIosInternalTestingSyncAllPressed(),
                            ),
                    icon: state.acting
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: cs.onSecondaryContainer,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: Text(
                      l10n.super_ios_internal_testing_sync_all_visible_pending,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () =>
                        bloc.add(const SuperAdminIosInternalTestingRefreshed()),
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: l10n.super_ios_internal_testing_refresh,
                  ),
                  const SizedBox(width: 4),
                ],
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: RefreshIndicator.adaptive(
                  onRefresh: () async =>
                      bloc.add(const SuperAdminIosInternalTestingRefreshed()),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _StatsRow(state: state, loading: isInitialLoad),
                      const SizedBox(height: 12),
                      _FilterBar(
                        searchCtrl: _searchCtrl,
                        selectedStatus: state.selectedStatus,
                        statuses: _statuses,
                        hasActive: _hasActive(state),
                        onStatusChanged: (s) => bloc
                            .add(SuperAdminIosInternalTestingStatusChanged(s)),
                        onReset: _reset,
                        l10n: l10n,
                      ),
                      const SizedBox(height: 14),
                      if (isInitialLoad)
                        const _SkeletonList()
                      else if (state.requests.isEmpty)
                        _EmptyState(l10n: l10n)
                      else if (items.isEmpty)
                        _FilteredEmpty(onReset: _reset, l10n: l10n)
                      else
                        Column(
                          children: items
                              .map((r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _RequestCard(
                                      request: r,
                                      onTap: () => _openDetail(ctx, r, bloc),
                                    ),
                                  ))
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

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SuperAdminIosInternalTestingState state;
  final bool loading;

  const _StatsRow({required this.state, required this.loading});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        _StatPill(
          icon: Icons.layers_rounded,
          label: l10n.super_ios_internal_testing_total,
          value: loading ? '—' : '${state.totalCount}',
          color: cs.primary,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.error_outline_rounded,
          label: l10n.super_ios_internal_testing_failed,
          value: loading ? '—' : '${state.failedCount}',
          color: state.failedCount > 0 ? cs.error : cs.outline,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.verified_rounded,
          label: l10n.super_ios_internal_testing_ready,
          value: loading ? '—' : '${state.readyCount}',
          color: cs.tertiary,
        ),
        const SizedBox(width: 8),
        _StatPill(
          icon: Icons.hourglass_top_rounded,
          label: 'Processing',
          value: loading ? '—' : '${state.processingCount}',
          color: cs.secondary,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: tt.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: color.withOpacity(.68),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

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

  String _label(String v) {
    switch (v.toUpperCase()) {
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
        return v;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: l10n.super_ios_internal_testing_search_hint,
              hintStyle: TextStyle(
                  color: cs.onSurface.withOpacity(.4), fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: cs.onSurface.withOpacity(.4)),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: searchCtrl,
                builder: (_, v, __) => v.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            size: 18,
                            color: cs.onSurface.withOpacity(.5)),
                        onPressed: searchCtrl.clear,
                        visualDensity: VisualDensity.compact,
                      )
                    : const SizedBox.shrink(),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: cs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withOpacity(.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: cs.outlineVariant.withOpacity(.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...statuses.map((s) {
                  final active = s == selectedStatus;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onStatusChanged(s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: active ? cs.primary : cs.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active
                                ? cs.primary
                                : cs.outlineVariant.withOpacity(.5),
                          ),
                        ),
                        child: Text(
                          _label(s),
                          style: tt.labelSmall?.copyWith(
                            color: active
                                ? cs.onPrimary
                                : cs.onSurface.withOpacity(.68),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (hasActive)
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 14),
                    label: Text(l10n.common_clear),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
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

// ─── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final SuperAdminIosInternalTestingRequestModel request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  String get _initial {
    final n = request.appNameSnapshot.trim();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String _date() {
    final dt = request.updatedAt ?? request.createdAt;
    if (dt == null) return '';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final appName = request.appNameSnapshot.trim().isNotEmpty
        ? request.appNameSnapshot
        : 'AUP ${request.ownerProjectLinkId}';
    final fullName = request.fullName;
    final date = _date();

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: request.isFailed
                  ? cs.error.withOpacity(.28)
                  : cs.outlineVariant.withOpacity(.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _initial,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (request.bundleIdSnapshot.trim().isNotEmpty) ...
                      [
                        const SizedBox(height: 1),
                        Text(
                          request.bundleIdSnapshot,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(.45),
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    const SizedBox(height: 3),
                    Text(
                      fullName.isNotEmpty
                          ? '$fullName · ${request.appleEmail}'
                          : request.appleEmail,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.58),
                      ),
                      maxLines: 1,
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
                      status: request.status, compact: true),
                  if (date.isNotEmpty) ...
                    [
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.35),
                          fontSize: 10,
                        ),
                      ),
                    ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withOpacity(.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail page ──────────────────────────────────────────────────────────────

class _DetailPage extends StatelessWidget {
  final SuperAdminIosInternalTestingRequestModel request;

  const _DetailPage({required this.request});

  String _dt(DateTime? dt) {
    if (dt == null) return '—';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min';
  }

  String get _initial {
    final n = request.appNameSnapshot.trim();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
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
      builder: (ctx, state) {
        final isActing =
            state.acting && state.actionRequestId == request.id;

        void process() =>
            ctx.read<SuperAdminIosInternalTestingBloc>().add(
                  SuperAdminIosInternalTestingProcessPressed(request.id),
                );

        void sync() =>
            ctx.read<SuperAdminIosInternalTestingBloc>().add(
                  SuperAdminIosInternalTestingSyncPressed(request.id),
                );

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: Text(appName, overflow: TextOverflow.ellipsis),
            scrolledUnderElevation: 1,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // Identity
              _Card(
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _initial,
                          style: tt.titleLarge?.copyWith(
                            color: cs.onPrimaryContainer,
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
                                color: cs.onSurface.withOpacity(.5),
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

              // Tester info
              _Card(
                title: 'Tester',
                child: Column(
                  children: [
                    if (fullName.isNotEmpty)
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Name',
                        value: fullName,
                      ),
                    _InfoRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Apple Email',
                      value: request.appleEmail,
                      copyable: true,
                    ),
                    _InfoRow(
                      icon: Icons.link_rounded,
                      label: l10n.super_ios_internal_testing_aup_label,
                      value: 'AUP ${request.ownerProjectLinkId}',
                    ),
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      label: l10n.super_ios_internal_testing_request_label,
                      value: '#${request.id}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Error banner
              if ((request.lastError ?? '').trim().isNotEmpty) ...
                [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.error.withOpacity(.07),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: cs.error.withOpacity(.18)),
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
                                color: cs.error, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

              // Timeline
              _Card(
                title: 'Timeline',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Requested',
                      value:
                          _dt(request.requestedAt ?? request.createdAt),
                    ),
                    if (request.processedAt != null)
                      _InfoRow(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Processed',
                        value: _dt(request.processedAt),
                      ),
                    if (request.acceptedAt != null)
                      _InfoRow(
                        icon: Icons.verified_outlined,
                        label: 'Accepted',
                        value: _dt(request.acceptedAt),
                      ),
                    if (request.readyAt != null)
                      _InfoRow(
                        icon: Icons.rocket_launch_outlined,
                        label: 'Ready',
                        value: _dt(request.readyAt),
                      ),
                    if (request.updatedAt != null)
                      _InfoRow(
                        icon: Icons.update_rounded,
                        label: 'Last Updated',
                        value: _dt(request.updatedAt),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Technical details (expandable)
              if ((request.appleUserId ?? '').isNotEmpty ||
                  (request.appleInvitationId ?? '').isNotEmpty) ...
                [
                  _ExpandableCard(
                    title: 'Technical Details',
                    children: [
                      _InfoRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Owner ID',
                        value: '${request.ownerId}',
                      ),
                      if ((request.appleUserId ?? '').isNotEmpty)
                        _InfoRow(
                          icon: Icons.person_pin_rounded,
                          label: 'Apple User ID',
                          value: request.appleUserId!,
                          mono: true,
                          copyable: true,
                        ),
                      if ((request.appleInvitationId ?? '').isNotEmpty)
                        _InfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'Invitation ID',
                          value: request.appleInvitationId!,
                          mono: true,
                          copyable: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

              // Actions
              _Card(
                title: 'Actions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: isActing ? null : process,
                      icon: isActing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Icon(
                              Icons.play_circle_outline_rounded),
                      label: Text(
                          l10n.super_ios_internal_testing_process),
                    ),
                    if (request.isSyncable) ...
                      [
                        const SizedBox(height: 10),
                        FilledButton.tonalIcon(
                          onPressed: isActing ? null : sync,
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
                          label:
                              Text(l10n.super_ios_internal_testing_sync),
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

// ─── Shared card ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Card({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...
            [
              Text(
                title!,
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.45),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(.4)),
              const SizedBox(height: 12),
            ],
          child,
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final bool copyable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withOpacity(.35)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(.43),
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
                      color: cs.onSurface.withOpacity(.82),
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

// ─── Expandable card ──────────────────────────────────────────────────────────

class _ExpandableCard extends StatefulWidget {
  final String title;
  final List<Widget> children;

  const _ExpandableCard({required this.title, required this.children});

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.code_rounded,
                      size: 16,
                      color: cs.onSurface.withOpacity(.38)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurface.withOpacity(.48),
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
                    color: cs.onSurface.withOpacity(.35),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...
            [
              Divider(
                  height: 1,
                  color: cs.outlineVariant.withOpacity(.35)),
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

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.45)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.science_outlined,
                size: 44, color: cs.primary.withOpacity(.55)),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.super_ios_internal_testing_empty_state,
            style:
                tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.45)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 40, color: cs.onSurface.withOpacity(.22)),
          const SizedBox(height: 12),
          Text(
            'No records match your filters',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(.55),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onReset,
            icon:
                const Icon(Icons.filter_alt_off_rounded, size: 15),
            label: Text(l10n.common_clear),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton loader ──────────────────────────────────────────────────────────

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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: cs.outlineVariant.withOpacity(.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
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
                    _Bone(width: 120, height: 13, base: base),
                    const SizedBox(height: 5),
                    _Bone(
                        width: 160,
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
