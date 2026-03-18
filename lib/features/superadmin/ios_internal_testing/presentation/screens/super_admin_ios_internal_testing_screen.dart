import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:build4all_manager/shared/widgets/app_search_bar.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/models/super_admin_ios_internal_testing_request_model.dart';
import '../../data/services/super_admin_ios_internal_testing_api.dart';
import '../bloc/super_admin_ios_internal_testing_bloc.dart';
import '../bloc/super_admin_ios_internal_testing_event.dart';
import '../bloc/super_admin_ios_internal_testing_state.dart';
import '../widgets/super_admin_ios_internal_testing_actions_sheet.dart'
    hide SuperAdminIosInternalTestingBloc;
import '../widgets/super_admin_ios_internal_testing_request_card.dart';

class SuperAdminIosInternalTestingScreen extends StatelessWidget {
  final Dio dio;

  const SuperAdminIosInternalTestingScreen({
    super.key,
    required this.dio,
  });

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

class _View extends StatelessWidget {
  const _View();

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
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<UiTokens>();
    final pad = tokens?.pagePad ?? const EdgeInsets.all(16);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<SuperAdminIosInternalTestingBloc,
        SuperAdminIosInternalTestingState>(
      listenWhen: (p, c) =>
          p.error != c.error ||
          p.notice != c.notice ||
          p.syncAllUpdatedCount != c.syncAllUpdatedCount,
      listener: (context, state) {
        if ((state.error ?? '').trim().isNotEmpty) {
          AppToast.error(context, state.error!);
          context.read<SuperAdminIosInternalTestingBloc>().add(
                const SuperAdminIosInternalTestingErrorCleared(),
              );
        }

        if (state.notice != null) {
          AppToast.success(context, _noticeText(l10n, state));
          context.read<SuperAdminIosInternalTestingBloc>().add(
                const SuperAdminIosInternalTestingNoticeCleared(),
              );
        }
      },
      builder: (context, state) {
        final groups = _groupRequests(state.filteredRequests);

        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    context.read<SuperAdminIosInternalTestingBloc>().add(
                          const SuperAdminIosInternalTestingRefreshed(),
                        );
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          pad.left,
                          8,
                          pad.right,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _CompactSummarySection(state: state),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          pad.left,
                          12,
                          pad.right,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _ToolbarCard(
                            state: state,
                            statuses: _statuses,
                            statusLabelBuilder: (value) =>
                                _statusLabel(l10n, value),
                            onSearchChanged: (q) {
                              context.read<SuperAdminIosInternalTestingBloc>().add(
                                    SuperAdminIosInternalTestingSearchChanged(q),
                                  );
                            },
                            onStatusChanged: (value) {
                              context.read<SuperAdminIosInternalTestingBloc>().add(
                                    SuperAdminIosInternalTestingStatusChanged(
                                      value,
                                    ),
                                  );
                            },
                            onSyncAll: () {
                              context.read<SuperAdminIosInternalTestingBloc>().add(
                                    const SuperAdminIosInternalTestingSyncAllPressed(),
                                  );
                            },
                            onRefresh: () {
                              context.read<SuperAdminIosInternalTestingBloc>().add(
                                    const SuperAdminIosInternalTestingRefreshed(),
                                  );
                            },
                          ),
                        ),
                      ),
                      if (state.loading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (state.filteredRequests.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l10n.super_ios_internal_testing_empty_state,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pad.left,
                            14,
                            pad.right,
                            18,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final group = groups[index];
                                return _ProjectSection(
                                  group: group,
                                  onProcess: (requestId) {
                                    context
                                        .read<SuperAdminIosInternalTestingBloc>()
                                        .add(
                                          SuperAdminIosInternalTestingProcessPressed(
                                            requestId,
                                          ),
                                        );
                                  },
                                  onSync: (requestId) {
                                    context
                                        .read<SuperAdminIosInternalTestingBloc>()
                                        .add(
                                          SuperAdminIosInternalTestingSyncPressed(
                                            requestId,
                                          ),
                                        );
                                  },
                                  isActing: (requestId) =>
                                      state.acting &&
                                      state.actionRequestId == requestId,
                                );
                              },
                              childCount: groups.length,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: SizedBox(height: pad.bottom),
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

  List<_ProjectGroup> _groupRequests(
    List<SuperAdminIosInternalTestingRequestModel> requests,
  ) {
    final grouped = <String, _ProjectGroup>{};

    for (final request in requests) {
      final title = request.appNameSnapshot.trim().isNotEmpty
          ? request.appNameSnapshot.trim()
          : 'AUP ${request.ownerProjectLinkId}';

      final key = '${request.ownerProjectLinkId}__${title.toLowerCase()}';

      grouped.putIfAbsent(
        key,
        () => _ProjectGroup(
          title: title,
          ownerProjectLinkId: request.ownerProjectLinkId,
          requests: [],
        ),
      );

      grouped[key]!.requests.add(request);
    }

    return grouped.values.toList();
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

  String _statusLabel(AppLocalizations l10n, String value) {
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
}

class _CompactSummarySection extends StatelessWidget {
  final SuperAdminIosInternalTestingState state;

  const _CompactSummarySection({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      _SummaryItem(
        title: l10n.super_ios_internal_testing_total,
        value: state.totalCount.toString(),
        icon: Icons.layers_rounded,
      ),
      _SummaryItem(
        title: l10n.super_ios_internal_testing_waiting,
        value: state.waitingCount.toString(),
        icon: Icons.schedule_rounded,
      ),
      _SummaryItem(
        title: l10n.super_ios_internal_testing_adding,
        value: state.addingCount.toString(),
        icon: Icons.settings_rounded,
      ),
      _SummaryItem(
        title: l10n.super_ios_internal_testing_failed,
        value: state.failedCount.toString(),
        icon: Icons.error_outline_rounded,
      ),
      _SummaryItem(
        title: l10n.super_ios_internal_testing_ready,
        value: state.readyCount.toString(),
        icon: Icons.verified_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 760;

        if (isMobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == items.length - 1 ? 0 : 10,
                  ),
                  child: SizedBox(
                    width: 150,
                    child: _MiniSummaryCard(
                      title: item.title,
                      value: item.value,
                      icon: item.icon,
                    ),
                  ),
                );
              }),
            ),
          );
        }

        return Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == items.length - 1 ? 0 : 10,
                ),
                child: _MiniSummaryCard(
                  title: item.title,
                  value: item.value,
                  icon: item.icon,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<UiTokens>();

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens?.radiusLg ?? 18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.30)),
        boxShadow: tokens?.cardShadow ?? const [],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: cs.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withOpacity(.72),
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

class _ToolbarCard extends StatelessWidget {
  final SuperAdminIosInternalTestingState state;
  final List<String> statuses;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSyncAll;
  final VoidCallback onRefresh;
  final String Function(String value) statusLabelBuilder;

  const _ToolbarCard({
    required this.state,
    required this.statuses,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSyncAll,
    required this.onRefresh,
    required this.statusLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<UiTokens>();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens?.radiusLg ?? 18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.30)),
        boxShadow: tokens?.cardShadow ?? const [],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 760;

          final search = AppSearchBar(
            hint: l10n.super_ios_internal_testing_search_hint,
            onQueryChanged: onSearchChanged,
            margin: EdgeInsets.zero,
          );

          final statusDropdown = DropdownButtonFormField<String>(
            value: state.selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.super_ios_internal_testing_status,
            ),
            items: statuses
                .map(
                  (s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(
                      statusLabelBuilder(s),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              onStatusChanged(value);
            },
          );

          final syncButton = SizedBox(
            height: 48,
            child: FilledButton.tonalIcon(
              onPressed: state.acting ? null : onSyncAll,
              icon: const Icon(Icons.sync_rounded),
              label: Text(
                l10n.super_ios_internal_testing_sync_all_visible_pending,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );

          final refreshButton = SizedBox(
            height: 48,
            width: 48,
            child: IconButton.filledTonal(
              onPressed: state.loading ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: l10n.super_ios_internal_testing_refresh,
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search,
                const SizedBox(height: 10),
                statusDropdown,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: syncButton),
                    const SizedBox(width: 10),
                    refreshButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: search,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 250,
                child: statusDropdown,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: syncButton),
                    const SizedBox(width: 10),
                    refreshButton,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectSection extends StatelessWidget {
  final _ProjectGroup group;
  final void Function(int requestId) onProcess;
  final void Function(int requestId) onSync;
  final bool Function(int requestId) isActing;

  const _ProjectSection({
    required this.group,
    required this.onProcess,
    required this.onSync,
    required this.isActing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<UiTokens>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens?.radiusLg ?? 18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.30)),
        boxShadow: tokens?.cardShadow ?? const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 560;

              final title = Text(
                group.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              );

              final badges = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SectionBadge(
                    icon: Icons.link_rounded,
                    text: 'AUP ${group.ownerProjectLinkId}',
                  ),
                  _SectionBadge(
                    icon: Icons.layers_rounded,
                    text: '${group.requests.length}',
                  ),
                ],
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 10),
                    badges,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  badges,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(group.requests.length, (index) {
              final request = group.requests[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == group.requests.length - 1 ? 0 : 10,
                ),
                child: SuperAdminIosInternalTestingRequestCard(
                  request: request,
                  acting: isActing(request.id),
                  showAppTitle: false,
                  onProcess: () => onProcess(request.id),
                  onSync: () => onSync(request.id),
                  onMore: () {
                    SuperAdminIosInternalTestingActionsSheet.show(
                      context,
                      request: request,
                      onProcess: () => onProcess(request.id),
                      onSync: () => onSync(request.id),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectGroup {
  final String title;
  final int ownerProjectLinkId;
  final List<SuperAdminIosInternalTestingRequestModel> requests;

  _ProjectGroup({
    required this.title,
    required this.ownerProjectLinkId,
    required this.requests,
  });
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}