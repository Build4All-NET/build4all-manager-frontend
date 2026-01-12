import 'package:build4all_manager/core/network/url_utils.dart';
import 'package:build4all_manager/core/network/url_utils.dart' as g;
import 'package:build4all_manager/features/superadmin/publish_admin/data/services/publish_admin_remote_ds.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/network/globals.dart' as g;
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/repositories/publish_admin_repo_impl.dart';

import '../../domain/entities/app_publish_request_admin.dart';
import '../../domain/usecases/approve_request.dart';
import '../../domain/usecases/reject_request.dart';

import '../bloc/publish_request_detail_bloc.dart';
import '../bloc/publish_request_detail_event.dart';
import '../bloc/publish_request_detail_state.dart';

import '../widgets/decision_sheet.dart';

class PublishRequestDetailScreen extends StatelessWidget {
  final AppPublishRequestAdmin item;
  const PublishRequestDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final dio = DioClient.ensure();
    final repo = PublishAdminRepoImpl(PublishAdminRemoteDs(dio: dio));

    return BlocProvider(
      create: (_) => PublishRequestDetailBloc(
        item: item,
        approve: ApproveRequest(repo),
        reject: RejectRequest(repo),
      ),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  String _abs(String? maybe) {
    final dio = DioClient.ensure();
    return g.absUrlFromDioBaseUrl(dio.options.baseUrl, maybe);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<PublishRequestDetailBloc, PublishRequestDetailState>(
      listenWhen: (p, c) => p.error != c.error || p.success != c.success,
      listener: (ctx, st) {
        if (st.error?.isNotEmpty == true) {
          AppToast.error(ctx, st.error!);
        }
        if (st.success == 'approved') {
          AppToast.success(ctx, l10n.toast_publish_approved);
          Navigator.pop(ctx, true);
        }
        if (st.success == 'rejected') {
          AppToast.success(ctx, l10n.toast_publish_rejected);
          Navigator.pop(ctx, true);
        }
      },
      builder: (context, state) {
        final item = state.item;

        return Scaffold(
          appBar: AppBar(
            title: Text(item.appName ?? l10n.publish_details_title),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _Header(item: item, abs: _abs),
              const SizedBox(height: 14),
              _Section(
                title: l10n.publish_section_basic,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(l10n.publish_label_platform, item.platform),
                    _kv(l10n.publish_label_store, item.store),
                    _kv(l10n.publish_label_status, item.status),
                    _kv(l10n.publish_label_aup, '${item.aupId ?? "-"}'),
                    if ((item.packageNameSnapshot ?? '').isNotEmpty)
                      _kv(l10n.publish_label_package,
                          item.packageNameSnapshot!),
                    if ((item.bundleIdSnapshot ?? '').isNotEmpty)
                      _kv(l10n.publish_label_bundle, item.bundleIdSnapshot!),
                    _kv(l10n.publish_label_pricing, item.pricing),
                    _kv(l10n.publish_label_category, item.category),
                    _kv(
                      l10n.publish_label_content_rating_confirmed,
                      item.contentRatingConfirmed ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: l10n.publish_section_descriptions,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, l10n.publish_label_short),
                    _text(context, item.shortDescription),
                    const SizedBox(height: 10),
                    _label(context, l10n.publish_label_full),
                    _text(context, item.fullDescription),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: l10n.publish_section_assets,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, l10n.publish_label_icon),
                    const SizedBox(height: 8),
                    _img(context, _abs(item.appIconUrl)),
                    const SizedBox(height: 12),
                    _label(context, l10n.publish_label_screenshots),
                    const SizedBox(height: 8),
                    if (item.screenshotsUrls.isEmpty)
                      _text(context, l10n.publish_label_no_screenshots)
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: item.screenshotsUrls
                            .map((u) => _thumb(_abs(u)))
                            .toList(),
                      ),
                  ],
                ),
              ),
              if ((item.adminNotes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _Section(
                  title: l10n.publish_section_admin_notes,
                  child: _text(context, item.adminNotes!),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: l10n.publish_action_reject,
                      type: AppButtonType.secondary,
                      expand: true,
                      isBusy: state.acting,
                      onPressed: (!item.isSubmitted || state.acting)
                          ? null
                          : () async {
                              final notes = await DecisionSheet.open(
                                context,
                                title: l10n.publish_sheet_reject_title,
                                confirmLabel: l10n.publish_action_reject,
                                hint: l10n.publish_sheet_notes_hint,
                                cancelLabel: l10n.common_cancel,
                              );
                              context
                                  .read<PublishRequestDetailBloc>()
                                  .add(PublishRequestReject(notes));
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: l10n.publish_action_approve,
                      type: AppButtonType.primary,
                      expand: true,
                      isBusy: state.acting,
                      onPressed: (!item.isSubmitted || state.acting)
                          ? null
                          : () async {
                              final notes = await DecisionSheet.open(
                                context,
                                title: l10n.publish_sheet_approve_title,
                                confirmLabel: l10n.publish_action_approve,
                                hint: l10n.publish_sheet_notes_hint,
                                cancelLabel: l10n.common_cancel,
                              );
                              context
                                  .read<PublishRequestDetailBloc>()
                                  .add(PublishRequestApprove(notes));
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String t) => Text(
        t,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      );

  Widget _text(BuildContext context, String t) => Text(
        t,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
      );

  Widget _img(BuildContext context, String url) {
    final cs = Theme.of(context).colorScheme;
    if (url.trim().isEmpty) {
      return Container(
        height: 64,
        width: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
        ),
        child: const Text('—'),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(url, height: 64, width: 64, fit: BoxFit.cover),
    );
  }

  Widget _thumb(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(url, height: 110, width: 110, fit: BoxFit.cover),
    );
  }
}

class _Header extends StatelessWidget {
  final AppPublishRequestAdmin item;
  final String Function(String?) abs;

  const _Header({required this.item, required this.abs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconUrl = abs(item.appIconUrl);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: iconUrl.isEmpty
                ? Container(
                    width: 58,
                    height: 58,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.apps_rounded, color: cs.primary),
                  )
                : Image.network(iconUrl,
                    width: 58, height: 58, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.appName ?? 'App',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(context, '${item.platform} • ${item.store}'),
                    _pill(context, 'Status: ${item.status}'),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  )),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
