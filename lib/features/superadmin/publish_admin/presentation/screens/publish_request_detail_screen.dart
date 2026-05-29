import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/network/url_utils.dart' as g;
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:build4all_manager/shared/widgets/app_button.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';

import '../../data/repositories/publish_admin_repo_impl.dart';
import '../../data/services/publish_admin_remote_ds.dart';
import '../../domain/entities/app_publish_request_admin.dart';
import '../../domain/usecases/approve_request.dart';
import '../../domain/usecases/reject_request.dart';
import '../bloc/publish_request_detail_bloc.dart';
import '../bloc/publish_request_detail_event.dart';
import '../bloc/publish_request_detail_state.dart';
import '../widgets/approve_with_firebase_sheet.dart';
import '../widgets/decision_sheet.dart';

class PublishRequestDetailScreen extends StatelessWidget {
  final AppPublishRequestAdmin item;

  const PublishRequestDetailScreen({
    super.key,
    required this.item,
  });

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

  static const _strut = StrutStyle(forceStrutHeight: true, height: 1.2);
  static const _thb = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  String _abs(String? maybe) {
    final dio = DioClient.ensure();
    return g.absUrlFromDioBaseUrl(dio.options.baseUrl, maybe);
  }

  bool _hasUrl(String? u) => (u ?? '').trim().isNotEmpty;

  Future<void> _openUrl(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final s = url.trim();

    if (s.isEmpty) {
      AppToast.info(context, l10n.publish_details_no_file_yet);
      return;
    }

    final uri = Uri.tryParse(s);
    if (uri == null) {
      AppToast.error(context, l10n.publish_details_invalid_url);
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.error(context, l10n.publish_details_could_not_open_link);
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String value) async {
    final l10n = AppLocalizations.of(context)!;
    final clean = value.trim();

    if (clean.isEmpty) {
      AppToast.info(context, l10n.publish_details_no_file_yet);
      return;
    }

    await Clipboard.setData(ClipboardData(text: clean));

    if (context.mounted) {
      AppToast.success(context, l10n.publish_share_link_copied);
    }
  }

  Future<void> _downloadUrl(BuildContext context, String url) async {
    // For now, download opens the asset/build URL externally.
    // The browser or file handler lets the admin save it.
    await _openUrl(context, url);
  }

  List<_AssetItem> _collectAssetItems(
    BuildContext context,
    AppPublishRequestAdmin item,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final assets = <_AssetItem>[];

    if (_hasUrl(item.logoUrl)) {
      assets.add(_AssetItem(title: l10n.publish_label_logo, url: _abs(item.logoUrl)));
    }

    if (_hasUrl(item.appIconUrl)) {
      assets.add(_AssetItem(title: l10n.publish_label_icon, url: _abs(item.appIconUrl)));
    }

    for (var i = 0; i < item.screenshotsUrls.length; i++) {
      final url = item.screenshotsUrls[i];
      if (_hasUrl(url)) {
        assets.add(
          _AssetItem(
            title: '${l10n.publish_label_screenshot} ${i + 1}',
            url: _abs(url),
          ),
        );
      }
    }

    return assets;
  }

  void _openAssetsViewer(
    BuildContext context,
    List<_AssetItem> assets, {
    int initialIndex = 0,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (assets.isEmpty) {
      AppToast.info(context, l10n.publish_label_no_screenshots);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (_) => _AssetsGallerySheet(
        assets: assets,
        initialIndex: initialIndex,
        onOpen: (url) => _openUrl(context, url),
        onCopy: (url) => _copyToClipboard(context, url),
      ),
    );
  }

  Future<void> _downloadAllAssets(
    BuildContext context,
    AppPublishRequestAdmin item,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // Professional flow: backend should expose a ZIP endpoint for all publishing images.
    // Expected backend endpoint:
    // GET /api/superadmin/publish-requests/{id}/assets.zip
    final zipUrl = _abs('/api/superadmin/publish-requests/${item.id}/assets.zip');
    final uri = Uri.tryParse(zipUrl);

    if (uri == null) {
      AppToast.error(context, l10n.publish_details_invalid_url);
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      AppToast.error(context, l10n.publish_assets_download_all_failed);
    }
  }

 Future<void> _sharePublishPackageByEmail(
  BuildContext context,
  AppPublishRequestAdmin item,
) async {
  final l10n = AppLocalizations.of(context)!;

  String dashIfEmpty(String? value) {
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? '—' : clean;
  }

  String urlOrDash(String? value) {
    if (!_hasUrl(value)) return '—';
    return _abs(value);
  }

  String line(String label, String value) {
    return '$label: $value';
  }

  String section(String title) {
    return '\r\n$title\r\n${'-' * title.length}';
  }

  final appName = item.appName ?? l10n.publish_unknown_app;

  final subject = l10n.publish_share_email_subject(appName);

  final body = [
    l10n.publish_share_email_intro,

    section(l10n.publish_share_section_app_info),
    line(l10n.publish_share_app_name, appName),
    line(l10n.publish_label_aup, item.aupId?.toString() ?? '—'),
    line(l10n.publish_label_status, _niceStatus(context, item.status)),

    section(l10n.publish_share_section_android),
    line(
      l10n.publish_details_label_package_name,
      dashIfEmpty(item.packageNameSnapshot),
    ),
    line(
      l10n.publish_table_version,
      dashIfEmpty(item.androidVersionName),
    ),
    line(
      l10n.publish_details_label_version_code,
      item.androidVersionCode?.toString() ?? '—',
    ),
    line(
      l10n.publish_details_file_aab,
      urlOrDash(item.bundleUrl),
    ),
    line(
      l10n.publish_details_file_apk,
      urlOrDash(item.apkUrl),
    ),

    section(l10n.publish_share_section_ios),
    line(
      l10n.publish_details_label_bundle_identifier,
      dashIfEmpty(item.bundleIdSnapshot),
    ),
    line(
      l10n.publish_table_version,
      dashIfEmpty(item.iosVersionName),
    ),
    line(
      l10n.publish_details_label_build_number,
      item.iosBuildNumber?.toString() ?? '—',
    ),
    line(
      l10n.publish_details_file_ipa,
      urlOrDash(item.ipaUrl),
    ),

    section(l10n.publish_share_section_assets),
    line(l10n.publish_label_logo, urlOrDash(item.logoUrl)),
    line(l10n.publish_label_icon, urlOrDash(item.appIconUrl)),
    l10n.publish_share_assets_hint,

    '\r\n${l10n.publish_share_email_footer}',
  ].join('\r\n');

  final mailto = Uri.parse(
    'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
  );

  final ok = await launchUrl(
    mailto,
    mode: LaunchMode.externalApplication,
  );

  if (!ok && context.mounted) {
    AppToast.error(context, l10n.publish_share_email_failed);
  }
}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        final cs = Theme.of(context).colorScheme;
        final tokens = Theme.of(context).extension<UiTokens>();
        final rLg = tokens?.radiusLg ?? 18.0;

        final w = MediaQuery.of(context).size.width;
        final isTight = w < 360;
        final twoCols = w >= 880;
        final gap = twoCols ? 14.0 : 12.0;

        final androidLine =
            '${l10n.publish_details_store_play} • ${item.packageNameSnapshot ?? "-"}';
        final iosLine =
            '${l10n.publish_details_store_app} • ${item.bundleIdSnapshot ?? "-"}';

        final androidTitle = l10n.publish_details_android_title;
        final androidSubtitle = l10n.publish_details_android_subtitle;
        final iosTitle = l10n.publish_details_ios_title;
        final iosSubtitle = l10n.publish_details_ios_subtitle;

        final headerIconUrl = _abs(
          _hasUrl(item.logoUrl) ? item.logoUrl : item.appIconUrl,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              item.appName ?? l10n.publish_details_title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              strutStyle: _strut,
              textHeightBehavior: _thb,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              _TopHeaderCard(
                iconUrl: headerIconUrl,
                title: item.appName ?? l10n.publish_unknown_app,
                subtitleLeft: '${l10n.publish_label_aup}: ${item.aupId ?? "-"}',
                subtitleRight:
                    '${l10n.publish_label_status}: ${_niceStatus(context, item.status)}',
                platformLine: InlinePlatformsLine(
                  androidText: androidLine,
                  iosText: iosLine,
                ),
              ),
              const SizedBox(height: 12),
              _SharePublishPackageCard(
                onShareEmail: () => _sharePublishPackageByEmail(context, item),
              ),
              const SizedBox(height: 12),
              if (twoCols)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PlatformCard(
                        tone: _PlatformTone.android,
                        title: androidTitle,
                        subtitle: androidSubtitle,
                        statusPill: _StatusPill(
                          label: _niceStatus(context, item.status),
                          type: _statusType(item.status),
                        ),
                        headerInlineLine: InlinePlatformsLine(
                          androidText: androidLine,
                          iosText: iosLine,
                          dense: true,
                        ),
                        rows: [
                          _kvRow(
                            context,
                            l10n.publish_details_label_package_name,
                            item.packageNameSnapshot ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_table_version,
                            item.androidVersionName ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_details_label_version_code,
                            item.androidVersionCode?.toString() ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_details_label_last_build,
                            _fmtDt(item.requestedAt) ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_details_file_apk,
                            _hasUrl(item.apkUrl)
                                ? l10n.publish_details_available
                                : '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_details_file_aab,
                            _hasUrl(item.bundleUrl)
                                ? l10n.publish_details_available
                                : '—',
                          ),
                        ],
                        downloads: [
                          _DownloadAction(
                            label: l10n.publish_details_file_aab,
                            icon: Icons.download_rounded,
                            enabled: _hasUrl(item.bundleUrl),
                            onPressed: () =>
                                _openUrl(context, _abs(item.bundleUrl)),
                          ),
                          _DownloadAction(
                            label: l10n.publish_details_file_apk,
                            icon: Icons.download_rounded,
                            enabled: _hasUrl(item.apkUrl),
                            onPressed: () =>
                                _openUrl(context, _abs(item.apkUrl)),
                          ),
                        ],
                        primaryCtaLabel: l10n.publish_details_cta_play_store,
                        primaryCtaEnabled: false,
                        onPrimaryCta: () => _comingSoon(context),
                        compact: isTight,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _PlatformCard(
                        tone: _PlatformTone.ios,
                        title: iosTitle,
                        subtitle: iosSubtitle,
                        statusPill: _StatusPill(
                          label: _niceStatus(context, item.status),
                          type: _statusType(item.status),
                        ),
                        headerInlineLine: InlinePlatformsLine(
                          androidText: androidLine,
                          iosText: iosLine,
                          dense: true,
                        ),
                        rows: [
                          _kvRow(
                            context,
                            l10n.publish_details_label_bundle_identifier,
                            item.bundleIdSnapshot ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_table_version,
                            item.iosVersionName ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_details_label_build_number,
                            item.iosBuildNumber?.toString() ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_details_label_last_build,
                            _fmtDt(item.requestedAt) ?? '—',
                          ),
                          _kvRow(
                            context,
                            l10n.publish_details_file_ipa,
                            _hasUrl(item.ipaUrl)
                                ? l10n.publish_details_available
                                : '—',
                          ),
                        ],
                        downloads: [
                          _DownloadAction(
                            label: l10n.publish_details_download_ipa,
                            icon: Icons.download_rounded,
                            enabled: _hasUrl(item.ipaUrl),
                            onPressed: () =>
                                _openUrl(context, _abs(item.ipaUrl)),
                          ),
                        ],
                        primaryCtaLabel: l10n.publish_details_cta_app_store,
                        primaryCtaEnabled: false,
                        onPrimaryCta: () => _comingSoon(context),
                        compact: isTight,
                      ),
                    ),
                  ],
                )
              else ...
                [
                  _PlatformCard(
                    tone: _PlatformTone.android,
                    title: androidTitle,
                    subtitle: androidSubtitle,
                    statusPill: _StatusPill(
                      label: _niceStatus(context, item.status),
                      type: _statusType(item.status),
                    ),
                    headerInlineLine: InlinePlatformsLine(
                      androidText: androidLine,
                      iosText: iosLine,
                      dense: true,
                    ),
                    rows: [
                      _kvRow(
                        context,
                        l10n.publish_details_label_package_name,
                        item.packageNameSnapshot ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_table_version,
                        item.androidVersionName ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_details_label_version_code,
                        item.androidVersionCode?.toString() ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_details_label_last_build,
                        _fmtDt(item.requestedAt) ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_details_file_apk,
                        _hasUrl(item.apkUrl)
                            ? l10n.publish_details_available
                            : '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_details_file_aab,
                        _hasUrl(item.bundleUrl)
                            ? l10n.publish_details_available
                            : '—',
                      ),
                    ],
                    downloads: [
                      _DownloadAction(
                        label: l10n.publish_details_file_aab,
                        icon: Icons.download_rounded,
                        enabled: _hasUrl(item.bundleUrl),
                        onPressed: () =>
                            _openUrl(context, _abs(item.bundleUrl)),
                      ),
                      _DownloadAction(
                        label: l10n.publish_details_file_apk,
                        icon: Icons.download_rounded,
                        enabled: _hasUrl(item.apkUrl),
                        onPressed: () => _openUrl(context, _abs(item.apkUrl)),
                      ),
                    ],
                    primaryCtaLabel: l10n.publish_details_cta_play_store,
                    primaryCtaEnabled: false,
                    onPrimaryCta: () => _comingSoon(context),
                    compact: isTight,
                  ),
                  const SizedBox(height: 12),
                  _PlatformCard(
                    tone: _PlatformTone.ios,
                    title: iosTitle,
                    subtitle: iosSubtitle,
                    statusPill: _StatusPill(
                      label: _niceStatus(context, item.status),
                      type: _statusType(item.status),
                    ),
                    headerInlineLine: InlinePlatformsLine(
                      androidText: androidLine,
                      iosText: iosLine,
                      dense: true,
                    ),
                    rows: [
                      _kvRow(
                        context,
                        l10n.publish_details_label_bundle_identifier,
                        item.bundleIdSnapshot ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_table_version,
                        item.iosVersionName ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_details_label_build_number,
                        item.iosBuildNumber?.toString() ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_details_label_last_build,
                        _fmtDt(item.requestedAt) ?? '—',
                      ),
                      _kvRow(
                        context,
                        l10n.publish_details_file_ipa,
                        _hasUrl(item.ipaUrl)
                            ? l10n.publish_details_available
                            : '—',
                      ),
                    ],
                    downloads: [
                      _DownloadAction(
                        label: l10n.publish_details_download_ipa,
                        icon: Icons.download_rounded,
                        enabled: _hasUrl(item.ipaUrl),
                        onPressed: () => _openUrl(context, _abs(item.ipaUrl)),
                      ),
                    ],
                    primaryCtaLabel: l10n.publish_details_cta_app_store,
                    primaryCtaEnabled: false,
                    onPrimaryCta: () => _comingSoon(context),
                    compact: isTight,
                  ),
                ],
              if (item.shortDescription.trim().isNotEmpty ||
                  item.fullDescription.trim().isNotEmpty) ...
                [
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.publish_section_descriptions,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                          strutStyle: _strut,
                          textHeightBehavior: _thb,
                        ),
                        const SizedBox(height: 10),
                        _label(context, l10n.publish_label_short),
                        const SizedBox(height: 6),
                        _safeText(context, item.shortDescription),
                        const SizedBox(height: 10),
                        _label(context, l10n.publish_label_full),
                        const SizedBox(height: 6),
                        _safeText(context, item.fullDescription),
                      ],
                    ),
                  ),
                ],
             if (item.screenshotsUrls.isNotEmpty ||
    _hasUrl(item.appIconUrl) ||
    _hasUrl(item.logoUrl)) ...[
  const SizedBox(height: 12),
  Builder(
    builder: (context) {
      final assets = _collectAssetItems(context, item);

      return _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.publish_section_assets,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                    strutStyle: _strut,
                    textHeightBehavior: _thb,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.publish_assets_view_all,
                  onPressed: assets.isEmpty
                      ? null
                      : () => _openAssetsViewer(context, assets),
                  icon: const Icon(Icons.photo_library_rounded),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: assets.isEmpty
                        ? null
                        : () => _openAssetsViewer(context, assets),
                    icon: const Icon(Icons.zoom_out_map_rounded, size: 18),
                    label: Text(
                      l10n.publish_assets_view_all,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: assets.isEmpty
                        ? null
                        : () => _downloadAllAssets(context, item),
                    icon: const Icon(Icons.archive_rounded, size: 18),
                    label: Text(
                      l10n.publish_assets_download_all,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (assets.isEmpty)
              _safeText(context, l10n.publish_label_no_screenshots)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  final crossAxisCount = width >= 700
                      ? 4
                      : width >= 460
                          ? 3
                          : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assets.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: .88,
                    ),
                    itemBuilder: (context, index) {
                      final asset = assets[index];

                      return _CompactAssetTile(
                        title: asset.title,
                        url: asset.url,
                        onPreview: () => _openAssetsViewer(
                          context,
                          assets,
                          initialIndex: index,
                        ),
                        onOpen: () => _openUrl(context, asset.url),
                        onDownload: () => _downloadUrl(context, asset.url),
                        onCopy: () => _copyToClipboard(context, asset.url),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      );
    },
  ),
],
              if ((item.adminNotes ?? '').trim().isNotEmpty) ...
                [
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.publish_section_admin_notes,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                          strutStyle: _strut,
                          textHeightBehavior: _thb,
                        ),
                        const SizedBox(height: 10),
                        _safeText(context, item.adminNotes!.trim()),
                      ],
                    ),
                  ),
                ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: l10n.publish_action_reject,
                        type: AppButtonType.secondary,
                        expand: true,
                        isBusy: state.acting,
                        onPressed: (!state.item.isSubmitted || state.acting)
                            ? null
                            : () async {
                                final notes = await DecisionSheet.open(
                                  context,
                                  title: l10n.publish_sheet_reject_title,
                                  confirmLabel: l10n.publish_action_reject,
                                  hint: l10n.publish_sheet_notes_hint,
                                  cancelLabel: l10n.common_cancel,
                                );

                                if (!context.mounted || notes == null) return;

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
                        onPressed: (!state.item.isSubmitted || state.acting)
                            ? null
                            : () async {
                                final result =
                                    await ApproveWithFirebaseSheet.open(
                                  context,
                                  title: l10n.publish_sheet_approve_title,
                                  confirmLabel: l10n.publish_action_approve,
                                  hint: l10n.publish_sheet_notes_hint,
                                  cancelLabel: l10n.common_cancel,
                                );

                                if (!context.mounted || result == null) return;

                                context
                                    .read<PublishRequestDetailBloc>()
                                    .add(PublishRequestApprove(
                                      result.notes,
                                      firebaseProjectAccountId:
                                          result.firebaseProjectAccountId,
                                    ));
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void _comingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    AppToast.info(context, l10n.publish_details_coming_soon);
  }

  static Widget _kvRow(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              k,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
              strutStyle: _strut,
              textHeightBehavior: _thb,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.15),
              strutStyle: _strut,
              textHeightBehavior: _thb,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _label(BuildContext context, String t) {
    return Text(
      t,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
      strutStyle: _strut,
      textHeightBehavior: _thb,
    );
  }

  static Widget _safeText(BuildContext context, String t) {
    return Text(
      t,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
      strutStyle: _strut,
      textHeightBehavior: _thb,
    );
  }

  static Widget _iconPreview(BuildContext context, String url) {
    final cs = Theme.of(context).colorScheme;

    if (url.trim().isEmpty) {
      return Container(
        height: 64,
        width: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
        ),
        child: const Text('—'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: 64,
        width: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 64,
          width: 64,
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.broken_image_rounded,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  static Widget _thumb(String url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: size,
          width: size,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_rounded),
        ),
      ),
    );
  }

  static String? _fmtDt(DateTime? dt) {
    if (dt == null) return null;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  static String _niceStatus(BuildContext context, String s) {
    final l10n = AppLocalizations.of(context)!;
    final x = s.toUpperCase();

    if (x == 'SUBMITTED') return l10n.publish_status_submitted;
    if (x == 'IN_REVIEW') return l10n.publish_status_in_review;
    if (x == 'APPROVED') return l10n.publish_status_approved;
    if (x == 'REJECTED') return l10n.publish_status_rejected;
    if (x == 'PUBLISHED') return l10n.publish_status_published;
    if (x == 'DRAFT') return l10n.publish_status_draft;
    if (x == 'PUBLISHING') return 'Publishing…';

    return s;
  }

  static _StatusType _statusType(String s) {
    final x = s.toUpperCase();
    if (x == 'PUBLISHED') return _StatusType.success;
    if (x == 'REJECTED') return _StatusType.danger;
    if (x == 'IN_REVIEW') return _StatusType.neutral;
    if (x == 'APPROVED' || x == 'PUBLISHING') return _StatusType.success;
    return _StatusType.info;
  }
}

class InlinePlatformsLine extends StatelessWidget {
  final String androidText;
  final String iosText;
  final bool dense;

  const InlinePlatformsLine({
    super.key,
    required this.androidText,
    required this.iosText,
    this.dense = false,
  });

  static const _strut = StrutStyle(forceStrutHeight: true, height: 1.2);
  static const _thb = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w900,
          height: 1.15,
        );

    Widget line({
      required IconData icon,
      required Color iconColor,
      required String text,
    }) {
      return Row(
        children: [
          Icon(icon, size: dense ? 14 : 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
              strutStyle: _strut,
              textHeightBehavior: _thb,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (ctx, c) {
        final narrow = c.maxWidth < (dense ? 420 : 480);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(
                      icon: Icons.android_rounded,
                      iconColor: const Color(0xFF16A34A),
                      text: androidText,
                    ),
                    const SizedBox(height: 6),
                    line(
                      icon: Icons.apple_rounded,
                      iconColor: const Color(0xFF111827),
                      text: iosText,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: line(
                        icon: Icons.android_rounded,
                        iconColor: const Color(0xFF16A34A),
                        text: androidText,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        width: 1,
                        height: 16,
                        color: cs.outlineVariant.withOpacity(.55),
                      ),
                    ),
                    Expanded(
                      child: line(
                        icon: Icons.apple_rounded,
                        iconColor: const Color(0xFF111827),
                        text: iosText,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<UiTokens>();
    final r = tokens?.radiusLg ?? 18.0;
    final shadow = tokens?.cardShadow ?? const <BoxShadow>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
        boxShadow: shadow,
      ),
      child: child,
    );
  }
}

class _AssetItem {
  final String title;
  final String url;

  const _AssetItem({
    required this.title,
    required this.url,
  });
}

class _AssetsGallerySheet extends StatefulWidget {
  final List<_AssetItem> assets;
  final int initialIndex;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onCopy;

  const _AssetsGallerySheet({
    required this.assets,
    required this.initialIndex,
    required this.onOpen,
    required this.onCopy,
  });

  @override
  State<_AssetsGallerySheet> createState() => _AssetsGallerySheetState();
}

class _AssetsGallerySheetState extends State<_AssetsGallerySheet> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.assets.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.assets[_index];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${current.title}  ${_index + 1}/${widget.assets.length}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: l10n.publish_asset_open,
            onPressed: () => widget.onOpen(current.url),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
          IconButton(
            tooltip: l10n.publish_asset_copy_link,
            onPressed: () => widget.onCopy(current.url),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.assets.length,
        onPageChanged: (value) {
          setState(() => _index = value);
        },
        itemBuilder: (context, index) {
          final asset = widget.assets[index];

          return Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.network(
                asset.url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Text(
            l10n.publish_assets_zoom_hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SharePublishPackageCard extends StatelessWidget {
  final VoidCallback onShareEmail;

  const _SharePublishPackageCard({
    required this.onShareEmail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return _Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;

          final info = Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.publish_share_package_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.publish_share_package_subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onShareEmail,
                  icon: const Icon(Icons.email_rounded, size: 18),
                  label: Text(
                    l10n.publish_share_email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: onShareEmail,
                icon: const Icon(Icons.email_rounded, size: 18),
                label: Text(
                  l10n.publish_share_email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompactAssetTile extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onPreview;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onCopy;

  const _CompactAssetTile({
    required this.title,
    required this.url,
    required this.onPreview,
    required this.onOpen,
    required this.onDownload,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withOpacity(.35),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPreview,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surface,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: cs.onSurfaceVariant,
                          size: 34,
                        ),
                      ),
                    ),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: PopupMenuButton<_AssetMenuAction>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          color: cs.surface,
                          tooltip: l10n.common_more,
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                          ),
                          onSelected: (action) {
                            switch (action) {
                              case _AssetMenuAction.open:
                                onOpen();
                                break;
                              case _AssetMenuAction.download:
                                onDownload();
                                break;
                              case _AssetMenuAction.copy:
                                onCopy();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: _AssetMenuAction.open,
                              child: _AssetMenuItem(
                                icon: Icons.open_in_new_rounded,
                                label: l10n.publish_asset_open,
                              ),
                            ),
                            PopupMenuItem(
                              value: _AssetMenuAction.download,
                              child: _AssetMenuItem(
                                icon: Icons.download_rounded,
                                label: l10n.publish_asset_download,
                              ),
                            ),
                            PopupMenuItem(
                              value: _AssetMenuAction.copy,
                              child: _AssetMenuItem(
                                icon: Icons.copy_rounded,
                                label: l10n.publish_asset_copy_link,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.50),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.zoom_out_map_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AssetMenuAction {
  open,
  download,
  copy,
}

class _AssetMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AssetMenuItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TopHeaderCard extends StatelessWidget {
  final String iconUrl;
  final String title;
  final String subtitleLeft;
  final String subtitleRight;
  final Widget platformLine;

  const _TopHeaderCard({
    required this.iconUrl,
    required this.title,
    required this.subtitleLeft,
    required this.subtitleRight,
    required this.platformLine,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _Card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: iconUrl.trim().isEmpty
                ? Container(
                    width: 58,
                    height: 58,
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.apps_rounded, color: cs.primary),
                  )
                : Image.network(
                    iconUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 58,
                      height: 58,
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: cs.onSurfaceVariant,
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _miniInfo(context, Icons.tag_rounded, subtitleLeft),
                    _miniInfo(context, Icons.timelapse_rounded, subtitleRight),
                  ],
                ),
                const SizedBox(height: 10),
                platformLine,
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniInfo(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PlatformTone { android, ios }

class _PlatformCard extends StatelessWidget {
  final _PlatformTone tone;
  final String title;
  final String subtitle;
  final _StatusPill statusPill;
  final Widget headerInlineLine;

  final List<Widget> rows;
  final List<_DownloadAction> downloads;

  final String primaryCtaLabel;
  final bool primaryCtaEnabled;
  final VoidCallback onPrimaryCta;

  final bool compact;

  const _PlatformCard({
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.statusPill,
    required this.headerInlineLine,
    required this.rows,
    required this.downloads,
    required this.primaryCtaLabel,
    required this.primaryCtaEnabled,
    required this.onPrimaryCta,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tokens = Theme.of(context).extension<UiTokens>();
    final r = tokens?.radiusLg ?? 18.0;

    final headerBg = tone == _PlatformTone.android
        ? const Color(0xFFECFDF3)
        : cs.surfaceContainerHighest;

    final leading = tone == _PlatformTone.android
        ? _toneBadge(bg: const Color(0xFF16A34A), icon: Icons.android_rounded)
        : _toneBadge(bg: const Color(0xFF111827), icon: Icons.apple_rounded);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withOpacity(.25)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: cs.onSurface.withOpacity(.65),
                                  height: 1.2,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    statusPill,
                  ],
                ),
                const SizedBox(height: 10),
                headerInlineLine,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...rows,
                const SizedBox(height: 10),
                Text(
                  l10n.publish_details_download_builds,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                        color: cs.onSurface.withOpacity(.7),
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (ctx, c) {
                    final stack = c.maxWidth < 420 || downloads.length == 1;

                    if (downloads.length == 1) {
                      return _AdaptiveIconButton(
                        label: downloads[0].label,
                        icon: downloads[0].icon,
                        enabled: downloads[0].enabled,
                        onPressed: downloads[0].onPressed,
                        compact: compact,
                      );
                    }

                    if (stack) {
                      return Column(
                        children: [
                          _AdaptiveIconButton(
                            label: downloads[0].label,
                            icon: downloads[0].icon,
                            enabled: downloads[0].enabled,
                            onPressed: downloads[0].onPressed,
                            compact: compact,
                          ),
                          const SizedBox(height: 10),
                          _AdaptiveIconButton(
                            label: downloads[1].label,
                            icon: downloads[1].icon,
                            enabled: downloads[1].enabled,
                            onPressed: downloads[1].onPressed,
                            compact: compact,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _AdaptiveIconButton(
                            label: downloads[0].label,
                            icon: downloads[0].icon,
                            enabled: downloads[0].enabled,
                            onPressed: downloads[0].onPressed,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AdaptiveIconButton(
                            label: downloads[1].label,
                            icon: downloads[1].icon,
                            enabled: downloads[1].enabled,
                            onPressed: downloads[1].onPressed,
                            compact: compact,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 46,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: primaryCtaEnabled ? onPrimaryCta : null,
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: compact ? 18 : 20,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        primaryCtaLabel,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 12.5 : 13.5,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _View._comingSoon(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_rounded,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.publish_details_manual_publish_instructions,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface.withOpacity(.75),
                                  height: 1.15,
                                ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _toneBadge({
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _DownloadAction {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _DownloadAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });
}

class _AdaptiveIconButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool compact;

  const _AdaptiveIconButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (ctx, c) {
        final tooTight = c.maxWidth < 120;

        if (tooTight) {
          return SizedBox(
            height: compact ? 38 : 40,
            child: OutlinedButton(
              onPressed: enabled ? onPressed : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide(color: cs.outlineVariant.withOpacity(.55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(icon, size: compact ? 16 : 18),
            ),
          );
        }

        return SizedBox(
          height: compact ? 38 : 40,
          child: OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(color: cs.outlineVariant.withOpacity(.55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: compact ? 16 : 18),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 12 : 13,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _StatusType { info, success, danger, neutral }

class _StatusPill extends StatelessWidget {
  final String label;
  final _StatusType type;

  const _StatusPill({
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color fg;
    Color bg;

    switch (type) {
      case _StatusType.success:
        fg = const Color(0xFF15803D);
        bg = const Color(0xFFDCFCE7);
        break;
      case _StatusType.danger:
        fg = const Color(0xFFB91C1C);
        bg = const Color(0xFFFEE2E2);
        break;
      case _StatusType.neutral:
        fg = cs.onSurfaceVariant;
        bg = cs.surfaceContainerHighest;
        break;
      case _StatusType.info:
      default:
        fg = cs.primary;
        bg = cs.primary.withOpacity(.10);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: fg,
              height: 1.15,
            ),
      ),
    );
  }
}
