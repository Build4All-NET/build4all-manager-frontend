import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/network/url_utils.dart' as g;
import 'package:build4all_manager/l10n/app_localizations.dart';
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

  bool _hasUrl(String? u) => (u ?? '').trim().isNotEmpty;

  Future<void> _openUrl(BuildContext context, String url) async {
    final s = url.trim();
    if (s.isEmpty) {
      AppToast.info(context, 'No file available yet');
      return;
    }
    final uri = Uri.tryParse(s);
    if (uri == null) {
      AppToast.error(context, 'Invalid URL');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.error(context, 'Could not open link');
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

        final w = MediaQuery.of(context).size.width;
        final isTight = w < 360;
        final twoCols = w >= 880;
        final gap = twoCols ? 14.0 : 12.0;

        final androidLine =
            'ANDROID • PLAY • ${item.packageNameSnapshot ?? "-"}';
        final iosLine = 'iOS • APP STORE • ${item.bundleIdSnapshot ?? "-"}';

        final headerIconUrl = _abs(
          _hasUrl(item.logoUrl) ? item.logoUrl : item.appIconUrl,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              item.appName ?? l10n.publish_details_title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            children: [
              _TopHeaderCard(
                iconUrl: headerIconUrl,
                title: item.appName ?? 'App',
                subtitleLeft: '${l10n.publish_label_aup}: ${item.aupId ?? "-"}',
                subtitleRight: '${l10n.publish_label_status}: ${item.status}',
                platformLine: InlinePlatformsLine(
                  androidText: androidLine,
                  iosText: iosLine,
                ),
              ),
              const SizedBox(height: 12),
              if (twoCols)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PlatformCard(
                        tone: _PlatformTone.android,
                        title: 'Android — Google Play',
                        subtitle: 'Build and publish to Play Store',
                        statusPill: _StatusPill(
                          label: _niceStatus(item.status),
                          type: _statusType(item.status),
                        ),
                        headerInlineLine: InlinePlatformsLine(
                          androidText:
                              'PLAY • ${item.packageNameSnapshot ?? "-"}',
                          iosText:
                              'APP STORE • ${item.bundleIdSnapshot ?? "-"}',
                          dense: true,
                        ),
                        rows: [
                          _kvRow(
                              'Package Name', item.packageNameSnapshot ?? '—'),
                          _kvRow('Version', item.androidVersionName ?? '—'),
                          _kvRow('Version Code',
                              item.androidVersionCode?.toString() ?? '—'),
                          _kvRow('Last Build', _fmtDt(item.requestedAt) ?? '—'),
                          _kvRow(
                              'APK', _hasUrl(item.apkUrl) ? 'Available' : '—'),
                          _kvRow('AAB',
                              _hasUrl(item.bundleUrl) ? 'Available' : '—'),
                        ],
                        downloads: [
                          _DownloadAction(
                            label: 'AAB',
                            icon: Icons.download_rounded,
                            enabled: _hasUrl(item.bundleUrl),
                            onPressed: () =>
                                _openUrl(context, _abs(item.bundleUrl)),
                          ),
                          _DownloadAction(
                            label: 'APK',
                            icon: Icons.download_rounded,
                            enabled: _hasUrl(item.apkUrl),
                            onPressed: () =>
                                _openUrl(context, _abs(item.apkUrl)),
                          ),
                        ],
                        primaryCtaLabel: 'Publish to Play Store',
                        primaryCtaEnabled: false,
                        onPrimaryCta: () => _comingSoon(context),
                        compact: isTight,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _PlatformCard(
                        tone: _PlatformTone.ios,
                        title: 'iOS — App Store',
                        subtitle: 'Build and publish to App Store',
                        statusPill: _StatusPill(
                          label: _niceStatus(item.status),
                          type: _statusType(item.status),
                        ),
                        headerInlineLine: InlinePlatformsLine(
                          androidText:
                              'PLAY • ${item.packageNameSnapshot ?? "-"}',
                          iosText:
                              'APP STORE • ${item.bundleIdSnapshot ?? "-"}',
                          dense: true,
                        ),
                        rows: [
                          _kvRow('Bundle Identifier',
                              item.bundleIdSnapshot ?? '—'),
                          _kvRow('Version', item.iosVersionName ?? '—'),
                          _kvRow('Build Number',
                              item.iosBuildNumber?.toString() ?? '—'),
                          _kvRow('Last Build', _fmtDt(item.requestedAt) ?? '—'),
                          _kvRow(
                              'IPA', _hasUrl(item.ipaUrl) ? 'Available' : '—'),
                        ],
                        downloads: [
                          _DownloadAction(
                            label: 'Download IPA',
                            icon: Icons.download_rounded,
                            enabled: _hasUrl(item.ipaUrl),
                            onPressed: () =>
                                _openUrl(context, _abs(item.ipaUrl)),
                          ),
                        ],
                        primaryCtaLabel: 'Publish to App Store',
                        primaryCtaEnabled: false,
                        onPrimaryCta: () => _comingSoon(context),
                        compact: isTight,
                      ),
                    ),
                  ],
                )
              else ...[
                _PlatformCard(
                  tone: _PlatformTone.android,
                  title: 'Android — Google Play',
                  subtitle: 'Build and publish to Play Store',
                  statusPill: _StatusPill(
                    label: _niceStatus(item.status),
                    type: _statusType(item.status),
                  ),
                  headerInlineLine: InlinePlatformsLine(
                    androidText: 'PLAY • ${item.packageNameSnapshot ?? "-"}',
                    iosText: 'APP STORE • ${item.bundleIdSnapshot ?? "-"}',
                    dense: true,
                  ),
                  rows: [
                    _kvRow('Package Name', item.packageNameSnapshot ?? '—'),
                    _kvRow('Version', _versionGuess(item, 'ANDROID')),
                    _kvRow('Version Code',
                        item.androidVersionCode?.toString() ?? '—'),
                    _kvRow('Last Build', _fmtDt(item.requestedAt) ?? '—'),
                    _kvRow('APK', _hasUrl(item.apkUrl) ? 'Available' : '—'),
                    _kvRow('AAB', _hasUrl(item.bundleUrl) ? 'Available' : '—'),
                  ],
                  downloads: [
                    _DownloadAction(
                      label: 'AAB',
                      icon: Icons.download_rounded,
                      enabled: _hasUrl(item.bundleUrl),
                      onPressed: () => _openUrl(context, _abs(item.bundleUrl)),
                    ),
                    _DownloadAction(
                      label: 'APK',
                      icon: Icons.download_rounded,
                      enabled: _hasUrl(item.apkUrl),
                      onPressed: () => _openUrl(context, _abs(item.apkUrl)),
                    ),
                  ],
                  primaryCtaLabel: 'Publish to Play Store',
                  primaryCtaEnabled: false,
                  onPrimaryCta: () => _comingSoon(context),
                  compact: isTight,
                ),
                const SizedBox(height: 12),
                _PlatformCard(
                  tone: _PlatformTone.ios,
                  title: 'iOS — App Store',
                  subtitle: 'Build and publish to App Store',
                  statusPill: _StatusPill(
                    label: _niceStatus(item.status),
                    type: _statusType(item.status),
                  ),
                  headerInlineLine: InlinePlatformsLine(
                    androidText: 'PLAY • ${item.packageNameSnapshot ?? "-"}',
                    iosText: 'APP STORE • ${item.bundleIdSnapshot ?? "-"}',
                    dense: true,
                  ),
                  rows: [
                    _kvRow('Bundle Identifier', item.bundleIdSnapshot ?? '—'),
                    _kvRow('Version', _versionGuess(item, 'IOS')),
                    _kvRow(
                        'Build Number', item.iosBuildNumber?.toString() ?? '—'),
                    _kvRow('Last Build', _fmtDt(item.requestedAt) ?? '—'),
                    _kvRow('IPA', _hasUrl(item.ipaUrl) ? 'Available' : '—'),
                  ],
                  downloads: [
                    _DownloadAction(
                      label: 'Download IPA',
                      icon: Icons.download_rounded,
                      enabled: _hasUrl(item.ipaUrl),
                      onPressed: () => _openUrl(context, _abs(item.ipaUrl)),
                    ),
                  ],
                  primaryCtaLabel: 'Publish to App Store',
                  primaryCtaEnabled: false,
                  onPrimaryCta: () => _comingSoon(context),
                  compact: isTight,
                ),
              ],
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Publishing Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (_) => _comingSoon(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publish automatically via CI/CD',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'When enabled, approved apps will be automatically published to Google Play Console and Apple App Store Connect using secure API integration.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: cs.onSurface.withOpacity(.65),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (ctx, c) {
                        final stack = c.maxWidth < 520;
                        final btnH = 46.0;

                        final btn1 = _BigCta(
                          label: 'Publish Android to Play Store',
                          icon: Icons.play_arrow_rounded,
                          enabled: false,
                          height: btnH,
                          onPressed: () => _comingSoon(context),
                          variant: _BigCtaVariant.green,
                        );
                        final btn2 = _BigCta(
                          label: 'Publish iOS to App Store',
                          icon: Icons.apple_rounded,
                          enabled: false,
                          height: btnH,
                          onPressed: () => _comingSoon(context),
                          variant: _BigCtaVariant.dark,
                        );
                        final btn3 = _BigCta(
                          label: 'Publish Both Platforms',
                          icon: Icons.send_rounded,
                          enabled: false,
                          height: btnH,
                          onPressed: () => _comingSoon(context),
                          variant: _BigCtaVariant.blue,
                        );

                        if (stack) {
                          return Column(
                            children: [
                              btn1,
                              const SizedBox(height: 10),
                              btn2,
                              const SizedBox(height: 10),
                              btn3,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: btn1),
                            const SizedBox(width: 12),
                            Expanded(child: btn2),
                            const SizedBox(width: 12),
                            Expanded(child: btn3),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if ((item.shortDescription).trim().isNotEmpty ||
                  (item.fullDescription).trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.publish_section_descriptions,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
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
                  (item.appIconUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.publish_section_assets,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 10),
                      _label(context, l10n.publish_label_icon),
                      const SizedBox(height: 8),
                      _iconPreview(context, _abs(item.appIconUrl)),
                      const SizedBox(height: 12),
                      _label(context, l10n.publish_label_screenshots),
                      const SizedBox(height: 8),
                      if (item.screenshotsUrls.isEmpty)
                        _safeText(context, l10n.publish_label_no_screenshots)
                      else
                        LayoutBuilder(
                          builder: (ctx, c) {
                            final thumb = c.maxWidth < 360 ? 86.0 : 104.0;
                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: item.screenshotsUrls
                                  .map((u) => _thumb(_abs(u), thumb))
                                  .toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
              if ((item.adminNotes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.publish_section_admin_notes,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
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
          ),
        );
      },
    );
  }

  // ---------- helpers ----------
  static void _comingSoon(BuildContext context) {
    AppToast.info(context, 'Coming soon 🚧');
  }

  static Widget _kvRow(String k, String v) {
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
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
          ),
    );
  }

  static Widget _safeText(BuildContext context, String t) {
    return Text(
      t,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
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
      child: Image.network(url, height: 64, width: 64, fit: BoxFit.cover),
    );
  }

  static Widget _thumb(String url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(url, height: size, width: size, fit: BoxFit.cover),
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

  static String _niceStatus(String s) {
    final x = s.toUpperCase();
    if (x == 'SUBMITTED') return 'Ready';
    if (x == 'IN_REVIEW') return 'Pending';
    if (x == 'APPROVED') return 'Approved';
    if (x == 'REJECTED') return 'Rejected';
    if (x == 'PUBLISHED') return 'Published';
    return s;
  }

  static _StatusType _statusType(String s) {
    final x = s.toUpperCase();
    if (x == 'PUBLISHED') return _StatusType.success;
    if (x == 'REJECTED') return _StatusType.danger;
    if (x == 'IN_REVIEW') return _StatusType.neutral;
    if (x == 'APPROVED') return _StatusType.success;
    return _StatusType.info;
  }

  static String _versionGuess(AppPublishRequestAdmin item, String platform) {
    final p = platform.toUpperCase();
    if (p == 'ANDROID') return item.androidVersionName ?? '—';
    return item.iosVersionName ?? '—';
  }
}

// ----------------- inline platforms line (NO overflow, SAME LINE) -----------------

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (ctx, c) {
        final tight = c.maxWidth < 360;
        final font = dense ? (tight ? 10.5 : 11.5) : (tight ? 11.2 : 12.2);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 10,
            vertical: dense ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
          ),
          child: Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '🤖 $androidText   |    $iosText',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: font,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------- UI blocks -----------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

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
      child: child,
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
                : Image.network(iconUrl,
                    width: 58, height: 58, fit: BoxFit.cover),
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

    final headerBg = tone == _PlatformTone.android
        ? const Color(0xFFECFDF3)
        : cs.surfaceContainerHighest;

    final leading = tone == _PlatformTone.android
        ? _toneBadge(bg: const Color(0xFF16A34A), icon: Icons.android_rounded)
        : _toneBadge(bg: const Color(0xFF111827), icon: Icons.apple_rounded);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(.35)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
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
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  'DOWNLOAD BUILDS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                        color: cs.onSurface.withOpacity(.7),
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
                    onPressed: onPrimaryCta,
                    icon:
                        Icon(Icons.play_arrow_rounded, size: compact ? 18 : 20),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        primaryCtaLabel,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 12.5 : 13.5,
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
                      Icon(Icons.description_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Manual Publish Instructions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface.withOpacity(.75),
                            ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.open_in_new_rounded,
                          size: 14, color: cs.onSurfaceVariant),
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

  static Widget _toneBadge({required Color bg, required IconData icon}) {
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
              onPressed: enabled ? onPressed : null, // ✅ REAL disable
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
            onPressed: enabled ? onPressed : null, // ✅ REAL disable
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

  const _StatusPill({required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color c;
    switch (type) {
      case _StatusType.success:
        c = Colors.green;
        break;
      case _StatusType.danger:
        c = Colors.red;
        break;
      case _StatusType.neutral:
        c = cs.onSurfaceVariant;
        break;
      default:
        c = cs.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

enum _BigCtaVariant { green, dark, blue }

class _BigCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final double height;
  final VoidCallback onPressed;
  final _BigCtaVariant variant;

  const _BigCta({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.height,
    required this.onPressed,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    const fg = Colors.white;

    switch (variant) {
      case _BigCtaVariant.green:
        bg = const Color(0xFF16A34A);
        break;
      case _BigCtaVariant.dark:
        bg = const Color(0xFF111827);
        break;
      default:
        bg = const Color(0xFF2563EB);
    }

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
