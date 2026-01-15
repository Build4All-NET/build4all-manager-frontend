import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/themes/app_theme.dart'; // UiTokens
import 'package:build4all_manager/shared/widgets/app_search_bar.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../../data/repositories/publish_admin_repo_impl.dart';
import '../../data/services/publish_admin_remote_ds.dart';
import '../../domain/usecases/get_publish_requests.dart';

import '../bloc/publish_requests_bloc.dart';
import '../bloc/publish_requests_event.dart';
import '../bloc/publish_requests_state.dart';

import '../widgets/publish_status_filter_button.dart';
import '../widgets/requested_apps_table_header.dart';
import '../widgets/requested_app_row.dart';

import 'publish_request_detail_screen.dart';
import 'publisher_profiles_screen.dart';

class PublishRequestsScreen extends StatelessWidget {
  final Dio dio;

  const PublishRequestsScreen({
    super.key,
    required this.dio,
  });

  @override
  Widget build(BuildContext context) {
    final repo = PublishAdminRepoImpl(PublishAdminRemoteDs(dio: dio));

    return BlocProvider(
      create: (_) => PublishRequestsBloc(
        getRequests: GetPublishRequests(repo),
      )..add(PublishRequestsLoad('SUBMITTED')),
      child: _View(dio: dio),
    );
  }
}

class _View extends StatelessWidget {
  final Dio dio;
  const _View({required this.dio});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<UiTokens>();

    final pad = tokens?.pagePad ?? const EdgeInsets.all(16);
    final rLg = tokens?.radiusLg ?? 18;
    final shadow = tokens?.cardShadow ?? const <BoxShadow>[];

    return BlocConsumer<PublishRequestsBloc, PublishRequestsState>(
      listenWhen: (p, c) => p.error != c.error,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) {
          AppToast.error(ctx, st.error!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: pad.left,
            title: Text(
              l10n.nav_publish_requests,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ✅ ONE scroll for the whole page
          body: RefreshIndicator.adaptive(
            onRefresh: () async {
              context.read<PublishRequestsBloc>().add(PublishRequestsRefresh());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // top padding
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad.left, 12, pad.right, 0),
                  sliver: SliverToBoxAdapter(
                    child: _PublisherProfilesProCard(
                      title: l10n.publish_manage_publisher_profiles,
                      subtitle: l10n.publish_profiles_required_hint,
                      onOpen: () => _openProfiles(context),
                    ),
                  ),
                ),

                // search + filter row
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad.left, 10, pad.right, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSearchBar(
                            hint: l10n.publish_search_hint,
                            onQueryChanged: (q) => context
                                .read<PublishRequestsBloc>()
                                .add(PublishRequestsSearchChanged(q)),
                            margin: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 10),
                        PublishStatusFilterButton(
                          value: state.status,
                          labelOf: (s) => _statusLabel(l10n, s),
                          onChanged: (s) => context
                              .read<PublishRequestsBloc>()
                              .add(PublishRequestsLoad(s)),
                        ),
                      ],
                    ),
                  ),
                ),

                // content
                if (state.loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (state.filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      title: l10n.publish_no_requests,
                      buttonLabel: l10n.common_refresh,
                      onRetry: () => context
                          .read<PublishRequestsBloc>()
                          .add(PublishRequestsLoad(state.status)),
                    ),
                  )
                else
                  // ✅ responsive width awareness INSIDE sliver
                  SliverLayoutBuilder(
                    builder: (ctx, constraints) {
                      final w = constraints.crossAxisExtent;
                      final showVersion = w >= 760;
                      final showRequested = w >= 640;

                      return SliverPadding(
                        padding:
                            EdgeInsets.fromLTRB(pad.left, 0, pad.right, 12),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(rLg),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(.35),
                              ),
                              boxShadow: shadow,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                RequestedAppsTableHeader(
                                  showVersion: showVersion,
                                  showRequested: showRequested,
                                ),
                                Divider(
                                  height: 1,
                                  color: cs.outlineVariant.withOpacity(.35),
                                ),

                                // ✅ IMPORTANT:
                                // No ListView here. We render rows directly so the WHOLE page scrolls.
                                ...List.generate(state.filtered.length, (i) {
                                  final item = state.filtered[i];
                                  final isLast = i == state.filtered.length - 1;

                                  return Column(
                                    children: [
                                      RequestedAppRow(
                                        item: item,
                                        showVersion: showVersion,
                                        showRequested: showRequested,
                                        onViewPublish: () async {
                                          final changed =
                                              await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PublishRequestDetailScreen(
                                                item: item,
                                              ),
                                            ),
                                          );

                                          if (changed == true &&
                                              context.mounted) {
                                            context
                                                .read<PublishRequestsBloc>()
                                                .add(PublishRequestsLoad(
                                                    state.status));
                                          }
                                        },
                                      ),
                                      if (!isLast)
                                        Divider(
                                          height: 1,
                                          color: cs.outlineVariant
                                              .withOpacity(.22),
                                        ),
                                    ],
                                  );
                                }),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // bottom breathing room (so last row doesn’t stick to bottom)
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProfiles(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublisherProfilesScreen(),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return l10n.publish_status_submitted;
      case 'IN_REVIEW':
        return l10n.publish_status_in_review;
      case 'APPROVED':
        return l10n.publish_status_approved;
      case 'REJECTED':
        return l10n.publish_status_rejected;
      case 'PUBLISHED':
        return l10n.publish_status_published;
      case 'DRAFT':
        return l10n.publish_status_draft;
      default:
        return status;
    }
  }
}

class _PublisherProfilesProCard extends StatelessWidget {
  final VoidCallback onOpen;
  final String title;
  final String subtitle;

  const _PublisherProfilesProCard({
    required this.onOpen,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<UiTokens>();

    final rLg = tokens?.radiusLg ?? 18;
    final shadow = tokens?.cardShadow ?? const <BoxShadow>[];

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(rLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(rLg),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rLg),
            border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
            boxShadow: shadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.storefront_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),

              // ✅ no overflow (ellipsis)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withOpacity(.65),
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ✅ safe + responsive action (no big button overflow)
              Tooltip(
                message: 'Open',
                child: IconButton(
                  onPressed: onOpen,
                  icon: const Icon(Icons.settings_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.title,
    required this.buttonLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, color: cs.onSurfaceVariant, size: 44),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface.withOpacity(.70),
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
