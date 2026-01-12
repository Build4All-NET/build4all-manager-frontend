import 'package:build4all_manager/features/superadmin/publish_admin/data/services/publish_admin_remote_ds.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/shared/widgets/app_search_bar.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/repositories/publish_admin_repo_impl.dart';
import '../../domain/usecases/get_publish_requests.dart';

import '../bloc/publish_requests_bloc.dart';
import '../bloc/publish_requests_event.dart';
import '../bloc/publish_requests_state.dart';

import '../widgets/publish_status_chips.dart';
import '../widgets/publish_request_card.dart';
import 'publish_request_detail_screen.dart';

class PublishRequestsScreen extends StatelessWidget {
  final Dio dio;

  const PublishRequestsScreen({
    super.key,
    required this.dio,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ USE the injected dio (no shadowing)
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
          appBar: AppBar(title: Text(l10n.nav_publish_requests)),
          body: Column(
            children: [
              PublishStatusChips(
                value: state.status,
                labelOf: (status) => _statusLabel(l10n, status),
                onChanged: (s) => context
                    .read<PublishRequestsBloc>()
                    .add(PublishRequestsLoad(s)),
              ),
              const SizedBox(height: 10),
              AppSearchBar(
                hint: l10n.publish_search_hint,
                onQueryChanged: (q) => context
                    .read<PublishRequestsBloc>()
                    .add(PublishRequestsSearchChanged(q)),
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
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
                                color: cs.onSurfaceVariant, size: 42),
                            const SizedBox(height: 8),
                            Text(
                              l10n.publish_no_requests,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface.withOpacity(.65),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => context
                                  .read<PublishRequestsBloc>()
                                  .add(PublishRequestsLoad('SUBMITTED')),
                              child: Text(l10n.common_refresh),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator.adaptive(
                      onRefresh: () async => context
                          .read<PublishRequestsBloc>()
                          .add(PublishRequestsRefresh()),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: state.filtered.length,
                        itemBuilder: (_, i) {
                          final item = state.filtered[i];
                          return PublishRequestCard(
                            item: item,
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PublishRequestDetailScreen(item: item),
                                ),
                              );

                              if (changed == true && context.mounted) {
                                context
                                    .read<PublishRequestsBloc>()
                                    .add(PublishRequestsLoad(state.status));
                              }
                            },
                          );
                        },
                      ),
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
