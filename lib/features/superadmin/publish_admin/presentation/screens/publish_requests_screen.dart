import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/shared/widgets/app_search_bar.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/repositories/publish_admin_repo_impl.dart';
import '../../domain/usecases/get_publish_requests.dart';
import '../../data/services/publish_admin_remote_ds.dart';

import '../bloc/publish_requests_bloc.dart';
import '../bloc/publish_requests_event.dart';
import '../bloc/publish_requests_state.dart';

import '../widgets/publish_status_filter_button.dart';
import '../widgets/requested_apps_table_header.dart';
import '../widgets/requested_app_row.dart';
import 'publish_request_detail_screen.dart';

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
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

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
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nav_publish_requests,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  // matches design vibe
                  'Review and publish mobile apps to Google Play and Apple App Store',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.65),
                        height: 1.25,
                      ),
                ),
              ],
            ),
            toolbarHeight: 82,
          ),
          body: Column(
            children: [
              // Search + filter row (like screenshot)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        hint: 'Search by app name, owner, or request ID...',
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

              Expanded(
                child: Builder(
                  builder: (_) {
                    if (state.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded,
                                color: cs.onSurfaceVariant, size: 44),
                            const SizedBox(height: 10),
                            Text(
                              l10n.publish_no_requests,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface.withOpacity(.70),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => context
                                  .read<PublishRequestsBloc>()
                                  .add(PublishRequestsLoad(state.status)),
                              child: Text(l10n.common_refresh),
                            ),
                          ],
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (ctx, c) {
                        final w = c.maxWidth;

                        // responsive “table”: on small screens we hide some columns
                        final showVersion = w >= 760;
                        final showRequested = w >= 640;

                        return Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: cs.outlineVariant.withOpacity(.35),
                            ),
                          ),
                          child: Column(
                            children: [
                              RequestedAppsTableHeader(
                                showVersion: showVersion,
                                showRequested: showRequested,
                              ),
                              Divider(
                                  height: 1,
                                  color: cs.outlineVariant.withOpacity(.35)),
                              Expanded(
                                child: RefreshIndicator.adaptive(
                                  onRefresh: () async => context
                                      .read<PublishRequestsBloc>()
                                      .add(PublishRequestsRefresh()),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    itemCount: state.filtered.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: cs.outlineVariant.withOpacity(.22),
                                    ),
                                    itemBuilder: (_, i) {
                                      final item = state.filtered[i];
                                      return RequestedAppRow(
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
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
