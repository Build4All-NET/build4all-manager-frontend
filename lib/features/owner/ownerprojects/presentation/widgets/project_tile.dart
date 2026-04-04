import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/domain/usecases/create_ios_internal_testing_request_uc.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/domain/usecases/get_ios_internal_testing_app_summary_uc.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/presentation/screens/owner_ios_internal_testing_screen.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../publish/data/services/owner_publish_api.dart';
import '../../../publish/domain/entities/publish_draft.dart';
import 'publish_wizard_dialog.dart';

class ProjectTile extends StatelessWidget {
  final OwnerProject project;
  final String serverRootNoApi;
  final OwnerPublishApi publishApi;

  final CreateIosInternalTestingRequestUc createIosInternalTestingRequestUc;
  final GetIosInternalTestingAppSummaryUc getIosInternalTestingAppSummaryUc;

  final String initialOwnerEmail;
  final String initialOwnerFirstName;
  final String initialOwnerLastName;

  final String? androidBuildStatusOverride;
  final String? iosBuildStatusOverride;
  final String? androidBuildErrorOverride;
  final String? iosBuildErrorOverride;

  final Future<void> Function(BuildContext ctx, OwnerProject p)? onRebuildAndroid;
  final Future<void> Function(BuildContext ctx, OwnerProject p)? onRebuildIos;
  final Future<void> Function(BuildContext ctx, OwnerProject p)? onDelete;

  const ProjectTile({
    super.key,
    required this.project,
    required this.serverRootNoApi,
    required this.publishApi,
    required this.createIosInternalTestingRequestUc,
    required this.getIosInternalTestingAppSummaryUc,
    this.initialOwnerEmail = '',
    this.initialOwnerFirstName = '',
    this.initialOwnerLastName = '',
    this.onRebuildAndroid,
    this.onRebuildIos,
    this.onDelete,
    this.androidBuildStatusOverride,
    this.iosBuildStatusOverride,
    this.androidBuildErrorOverride,
    this.iosBuildErrorOverride,
  });

  String _abs(String? maybe) {
    if (maybe == null) return '';
    final s0 = maybe.trim();
    if (s0.isEmpty || s0.toLowerCase() == 'null') return '';

    if (s0.startsWith('http://') || s0.startsWith('https://')) {
      return Uri.parse(s0).toString();
    }

    if (s0.startsWith('//')) {
      return Uri.parse('https:$s0').toString();
    }

    final base = serverRootNoApi.replaceAll(RegExp(r'/+$'), '');
    final rel = s0.startsWith('/') ? s0 : '/$s0';
    return Uri.parse('$base$rel').toString();
  }

  Future<void> _openUrl(BuildContext context, String urlStr) async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = urlStr.trim();

    if (cleaned.isEmpty) {
      AppToast.error(context, l10n.owner_project_err_no_link_open);
      return;
    }

    final uri = Uri.tryParse(cleaned);
    if (uri == null) {
      AppToast.error(context, l10n.owner_project_err_invalid_url);
      return;
    }

    if (!await canLaunchUrl(uri)) {
      AppToast.error(
        context,
        '${l10n.owner_project_err_cannot_open}: $cleaned',
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = url.trim();

    if (cleaned.isEmpty) {
      AppToast.error(context, l10n.owner_project_err_no_link_copy);
      return;
    }

    await Clipboard.setData(ClipboardData(text: cleaned));
    AppToast.success(context, l10n.owner_project_link_copied);
  }

  Future<void> _shareLink(
    BuildContext context,
    String url,
    String label,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = url.trim();

    if (cleaned.isEmpty) {
      AppToast.error(context, l10n.owner_project_err_no_link_share);
      return;
    }

    final uri = Uri.tryParse(cleaned);
    if (uri == null || !uri.hasScheme) {
      AppToast.error(context, l10n.owner_project_err_invalid_url);
      return;
    }

    try {
      final overlayBox =
          Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;

      final origin = overlayBox != null
          ? (Offset.zero & overlayBox.size)
          : const Rect.fromLTWH(0, 0, 1, 1);

      await Share.share(
        cleaned,
        subject: label,
        sharePositionOrigin: origin,
      );
    } catch (e, st) {
      debugPrint('Share failed: $e');
      debugPrint('$st');
      AppToast.error(context, '${l10n.owner_project_err_share_failed}: $e');
    }
  }

  String _normalizeBuildStatus(String? raw, {required bool hasArtifact}) {
    final s = (raw ?? '').trim();
    if (s.isEmpty || s.toLowerCase() == 'null') {
      return hasArtifact ? 'SUCCESS' : 'NOT_BUILT';
    }
    return s.toUpperCase();
  }

  bool _isRunning(String status) {
    final low = status.toLowerCase();
    return low.contains('queued') ||
        low.contains('building') ||
        low.contains('running') ||
        low.contains('started') ||
        low.contains('processing');
  }

  bool _isDone(String status) {
    final low = status.trim().toLowerCase();
    return low.contains('success') ||
        low.contains('done') ||
        low.contains('completed') ||
        low.contains('ready') ||
        low.contains('finished') ||
        low.contains('uploaded');
  }

  Color _buildColor(ColorScheme cs, String status) {
    final low = status.toLowerCase();

    if (low.contains('success') ||
        low.contains('done') ||
        low.contains('completed') ||
        low.contains('ready') ||
        low.contains('finished') ||
        low.contains('uploaded')) {
      return const Color(0xFF22C55E);
    }
    if (low.contains('fail') ||
        low.contains('error') ||
        low.contains('reject') ||
        low.contains('cancel')) {
      return const Color(0xFFEF4444);
    }
    if (low.contains('queued')) {
      return const Color(0xFFF59E0B);
    }
    if (low.contains('building') ||
        low.contains('running') ||
        low.contains('started') ||
        low.contains('processing')) {
      return const Color(0xFF0B6BFF);
    }

    return cs.outline;
  }

  String _projectStatusRaw() {
    final raw = project.status.trim();
    final low = raw.toLowerCase();

    if (raw.isEmpty || low == 'null') return 'unknown';
    if (low.split(RegExp(r'\s+')).first == 'active') return 'test';
    if (low.contains('production') || low.contains('prod')) return 'production';
    if (low.contains('local')) return 'local';
    if (low == 'active') return 'active';

    return raw.toUpperCase();
  }

  String _projectStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final raw = _projectStatusRaw();
    final low = raw.toLowerCase();

    switch (low) {
      case 'unknown':
        return l10n.common_unknown;
      case 'test':
        return l10n.common_status_test;
      case 'production':
        return l10n.common_status_production;
      case 'local':
        return l10n.common_status_local;
      case 'active':
        return l10n.common_status_active;
      default:
        return raw;
    }
  }

  Color _statusColor(ColorScheme cs, String rawStatus) {
    final low = rawStatus.toLowerCase();

    if (low == 'unknown') return cs.outline;
    if (low.contains('fail') ||
        low.contains('error') ||
        low.contains('reject')) {
      return cs.error;
    }
    if (low.contains('test')) return cs.primary;
    if (low.contains('review')) return cs.primary;
    if (low.contains('prod') || low.contains('production')) {
      return cs.tertiary;
    }
    if (low.contains('local')) return cs.outlineVariant;
    if (low.contains('active')) return cs.primary;

    return cs.primary;
  }

  String _buildStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    final low = status.trim().toLowerCase();

    if (low.isEmpty || low == 'not_built') {
      return l10n.owner_project_not_requested;
    }

    if (low.contains('success') ||
        low.contains('done') ||
        low.contains('completed') ||
        low.contains('ready') ||
        low.contains('finished') ||
        low.contains('uploaded')) {
      return l10n.owner_project_ready;
    }

    if (low.contains('fail') ||
        low.contains('error') ||
        low.contains('reject') ||
        low.contains('cancel')) {
      return l10n.owner_project_build_failed;
    }

    if (low.contains('queued')) {
      return l10n.owner_projects_rebuild_queued;
    }

    if (low.contains('building') ||
        low.contains('running') ||
        low.contains('started') ||
        low.contains('processing')) {
      return l10n.owner_project_building;
    }

    return status.toUpperCase();
  }

  Future<void> _handleRebuild(
    BuildContext context,
    String platformStatus, {
    required bool isAndroid,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    if (_isRunning(platformStatus)) {
      AppToast.success(context, l10n.owner_projects_rebuild_queued);
      return;
    }

    if (isAndroid) {
      if (onRebuildAndroid != null) {
        await onRebuildAndroid!(context, project);
      }
    } else {
      if (onRebuildIos != null) {
        await onRebuildIos!(context, project);
      }
    }
  }

  void _openInternalTestingPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OwnerIosInternalTestingScreen(
          project: project,
          createUc: createIosInternalTestingRequestUc,
          summaryUc: getIosInternalTestingAppSummaryUc,
          initialEmail: initialOwnerEmail,
          initialFirstName: initialOwnerFirstName,
          initialLastName: initialOwnerLastName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final width = MediaQuery.of(context).size.width;
    final bool small = width < 390;

    final appName =
        project.appName.isNotEmpty ? project.appName : project.projectName;

    final rawStatus = _projectStatusRaw();
    final statusLabel = _projectStatusText(context);
    final statusColor = _statusColor(cs, rawStatus);

    final apkUrl = _abs(project.apkUrl);
    final bundleUrl = _abs(project.bundleUrl);
    final androidUrl = apkUrl.isNotEmpty ? apkUrl : bundleUrl;
    final androidHasArtifact = androidUrl.isNotEmpty;

    final iosUrl = _abs(project.ipaUrl);
    final iosHasArtifact = iosUrl.isNotEmpty;

    final androidBuildFromModel = _normalizeBuildStatus(
      project.androidBuildStatus,
      hasArtifact: androidHasArtifact,
    );
    final iosBuildFromModel = _normalizeBuildStatus(
      project.iosBuildStatus,
      hasArtifact: iosHasArtifact,
    );

    final androidBuild = androidBuildStatusOverride ?? androidBuildFromModel;
    final iosBuild = iosBuildStatusOverride ?? iosBuildFromModel;

    final androidBuildLabel = _buildStatusText(context, androidBuild);
    final iosBuildLabel = _buildStatusText(context, iosBuild);

    final androidBuildColor = _buildColor(cs, androidBuild);
    final iosBuildColor = _buildColor(cs, iosBuild);

    final androidErr =
        (androidBuildErrorOverride ?? (project.androidBuildError ?? '')).trim();
    final iosErr =
        (iosBuildErrorOverride ?? (project.iosBuildError ?? '')).trim();

    final showAndroidErr =
        androidBuild.toLowerCase().contains('fail') && androidErr.isNotEmpty;
    final showIosErr =
        iosBuild.toLowerCase().contains('fail') && iosErr.isNotEmpty;

    final androidReady = androidHasArtifact && _isDone(androidBuild);
    final iosReady = iosHasArtifact && _isDone(iosBuild);

    final androidShareLabel = l10n.owner_project_share_android(
      appName,
      apkUrl.isNotEmpty ? l10n.owner_project_apk : l10n.owner_project_aab,
    );
    final iosShareLabel = l10n.owner_project_share_ios(appName);

    final String idLine =
        (project.packageOrBundleId is String ? project.packageOrBundleId as String : '')
            .trim();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    final base = cs.surface;

    final headerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              mix(base, cs.primary, 0.14),
              mix(base, cs.primary, 0.07),
              mix(base, cs.secondary, 0.10),
            ]
          : [
              mix(base, Colors.white, 0.82),
              mix(base, cs.primary, 0.03),
              mix(base, cs.secondary, 0.03),
            ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(.85),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(gradient: headerGradient),
            child: Padding(
              padding: EdgeInsets.all(small ? 10 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AppIcon(
                    project: project,
                    serverRootNoApi: serverRootNoApi,
                    size: small ? 42 : 46,
                    radius: 12,
                    band: cs.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          appName,
                          maxLines: 1,
                          minFontSize: 13,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: small ? 16 : 18,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AutoSizeText(
                          project.slug,
                          maxLines: 1,
                          minFontSize: 10.5,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(.72),
                            fontWeight: FontWeight.w700,
                            fontSize: small ? 12 : 13,
                          ),
                        ),
                        if (idLine.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          AutoSizeText(
                            idLine,
                            maxLines: 1,
                            minFontSize: 10,
                            stepGranularity: 0.5,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(.58),
                              fontFamily: 'monospace',
                              fontSize: small ? 11.5 : 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusPill(
                        label: statusLabel,
                        color: statusColor,
                        small: true,
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            splashRadius: 18,
                            tooltip: l10n.common_delete,
                            onPressed: () => onDelete!(context, project),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: cs.error,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),
          Padding(
            padding: EdgeInsets.all(small ? 8 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PlatformCard(
                    title: l10n.owner_project_android,
                    icon: Icons.android_rounded,
                    iconColor: const Color(0xFF22C55E),
                    statusText: androidBuildLabel,
                    statusColor: androidBuildColor,
                    showErrorBox: showAndroidErr,
                    errorBoxText: androidErr,
                    actionButtons: [
                      _CardActionData(
                        label: l10n.common_copy,
                        icon: Icons.copy_rounded,
                        enabled: androidReady,
                        onTap: () => _copyLink(context, androidUrl),
                      ),
                      _CardActionData(
                        label: l10n.common_share,
                        icon: Icons.share_rounded,
                        enabled: androidReady,
                        onTap: () => _shareLink(
                          context,
                          androidUrl,
                          androidShareLabel,
                        ),
                      ),
                    ],
                    primaryText: l10n.common_download,
                    primaryIcon: Icons.download_rounded,
                    primaryLeading: null,
                    primaryEnabled: androidReady,
                    onPrimary: () => _openUrl(context, androidUrl),
                    secondaryText: l10n.owner_project_publish,
                    secondaryIcon: Icons.upload_rounded,
                    secondaryEnabled: androidReady,
                    onSecondary: () => PublishWizardDialog.open(
                      context,
                      api: publishApi,
                      aupId: project.linkId,
                      appName: appName,
                      platform: PublishPlatform.android,
                      store: PublishStore.playStore,
                      androidPackageName: project.androidPackageName,
                    ),
                    showRebuild: true,
                    rebuildEnabled: true,
                    rebuildText: l10n.owner_project_retry_build,
                    rebuildColor: const Color(0xFFEF4444),
                    onRebuild: () => _handleRebuild(
                      context,
                      androidBuild,
                      isAndroid: true,
                    ),
                  ),
                ),
                SizedBox(width: small ? 8 : 10),
                Expanded(
                  child: _PlatformCard(
                    title: l10n.owner_project_ios,
                    icon: Icons.apple_rounded,
                    iconColor: const Color(0xFF2563EB),
                    statusText: iosBuildLabel,
                    statusColor: iosBuildColor,
                    showErrorBox: showIosErr,
                    errorBoxText: iosErr,
                    actionButtons: [
                      _CardActionData(
                        label: l10n.common_copy,
                        icon: Icons.copy_rounded,
                        enabled: iosReady,
                        onTap: () => _copyLink(context, iosUrl),
                      ),
                      _CardActionData(
                        label: l10n.common_share,
                        icon: Icons.share_rounded,
                        enabled: iosReady,
                        onTap: () => _shareLink(
                          context,
                          iosUrl,
                          iosShareLabel,
                        ),
                      ),
                    _CardActionData(
                      label: l10n.owner_project_external_testflight,
                      tooltip: l10n.owner_project_external_testflight,
                      icon: Icons.open_in_new_rounded,
                      leading: const _TestFlightLikeIcon(size: 14),
                      iconOnly: true,
                      enabled: iosReady,
                      onTap: () => _openUrl(context, iosUrl),
                    ),
                                        ],
                   primaryText: l10n.owner_project_add_internal_testers,
                    primaryIcon: Icons.group_add_rounded,
                    primaryLeading: const _TestFlightLikeIcon(size: 16),
                    primaryEnabled: iosReady,
                    onPrimary: () => _openInternalTestingPage(context),
                    secondaryText: l10n.owner_project_publish,
                    secondaryIcon: Icons.upload_rounded,
                    secondaryEnabled: iosReady,
                    onSecondary: () => PublishWizardDialog.open(
                      context,
                      api: publishApi,
                      aupId: project.linkId,
                      appName: appName,
                      platform: PublishPlatform.ios,
                      store: PublishStore.appStore,
                      iosBundleId: project.iosBundleId,
                    ),
                    showRebuild: true,
                    rebuildEnabled: true,
                    rebuildText: l10n.owner_project_retry_build,
                    rebuildColor: const Color(0xFFEF4444),
                    onRebuild: () => _handleRebuild(
                      context,
                      iosBuild,
                      isAndroid: false,
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

class _PlatformCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  final String statusText;
  final Color statusColor;

  final bool showErrorBox;
  final String errorBoxText;

  final List<_CardActionData> actionButtons;

  final String primaryText;
  final IconData primaryIcon;
  final Widget? primaryLeading;
  final bool primaryEnabled;
  final VoidCallback onPrimary;

  final String secondaryText;
  final IconData secondaryIcon;
  final bool secondaryEnabled;
  final VoidCallback onSecondary;

  final bool showRebuild;
  final bool rebuildEnabled;
  final String rebuildText;
  final Color rebuildColor;
  final VoidCallback onRebuild;

  const _PlatformCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.statusText,
    required this.statusColor,
    required this.showErrorBox,
    required this.errorBoxText,
    required this.actionButtons,
    required this.primaryText,
    required this.primaryIcon,
    required this.primaryLeading,
    required this.primaryEnabled,
    required this.onPrimary,
    required this.secondaryText,
    required this.secondaryIcon,
    required this.secondaryEnabled,
    required this.onSecondary,
    required this.showRebuild,
    required this.rebuildEnabled,
    required this.rebuildText,
    required this.rebuildColor,
    required this.onRebuild,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final bool small = width < 390;

    return Container(
      padding: EdgeInsets.all(small ? 8 : 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: AutoSizeText(
                  title,
                  maxLines: 1,
                  minFontSize: 11.5,
                  stepGranularity: 0.5,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: small ? 14 : 15,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MiniPill(
                text: statusText,
                color: statusColor,
              ),
            ],
          ),
          if (showErrorBox) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFDC2626),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AutoSizeText(
                      errorBoxText,
                      maxLines: 2,
                      minFontSize: 10.0,
                      stepGranularity: 0.5,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        fontSize: 12,
                        height: 1.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < actionButtons.length; i++) ...[
                Expanded(
                  child: _TopActionButton(data: actionButtons[i]),
                ),
                if (i != actionButtons.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (showRebuild) ...[
            _WidePillButton(
              enabled: rebuildEnabled,
              text: rebuildText,
              icon: Icons.refresh_rounded,
              leading: null,
              fillColor: Colors.transparent,
              borderColor: rebuildColor,
              textColor: rebuildColor,
              onTap: onRebuild,
            ),
            const SizedBox(height: 8),
          ],
          _WidePillButton(
            enabled: primaryEnabled,
            text: primaryText,
            icon: primaryIcon,
            leading: primaryLeading,
            fillColor: const Color(0xFF0B6BFF),
            borderColor: const Color(0xFF0B6BFF),
            textColor: Colors.white,
            onTap: onPrimary,
          ),
          const SizedBox(height: 8),
          _WidePillButton(
            enabled: secondaryEnabled,
            text: secondaryText,
            icon: secondaryIcon,
            leading: null,
            fillColor: Colors.transparent,
            borderColor: const Color(0xFF16A34A),
            textColor: const Color(0xFF16A34A),
            onTap: onSecondary,
          ),
        ],
      ),
    );
  }
}

class _CardActionData {
  final String label;
  final String? tooltip;
  final IconData icon;
  final Widget? leading;
  final bool enabled;
  final bool iconOnly;
  final VoidCallback onTap;

  const _CardActionData({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.leading,
    this.tooltip,
    this.iconOnly = false,
  });
}

class _TopActionButton extends StatelessWidget {
  final _CardActionData data;

  const _TopActionButton({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Opacity(
      opacity: data.enabled ? 1 : .35,
      child: IgnorePointer(
        ignoring: !data.enabled,
        child: Tooltip(
          message: data.tooltip ?? data.label,
          child: InkWell(
            onTap: data.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              padding: EdgeInsets.symmetric(horizontal: data.iconOnly ? 0 : 6),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withOpacity(.7)),
              ),
              child: Center(
                child: data.iconOnly
                    ? (data.leading ??
                        Icon(
                          data.icon,
                          size: 14,
                          color: const Color(0xFF0B6BFF),
                        ))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            data.leading ??
                                Icon(
                                  data.icon,
                                  size: 14,
                                  color: const Color(0xFF0B6BFF),
                                ),
                            const SizedBox(width: 4),
                            Text(
                              data.label,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 9.2,
                                color: cs.onSurface.withOpacity(.90),
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WidePillButton extends StatelessWidget {
  final bool enabled;
  final String text;
  final IconData icon;
  final Widget? leading;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _WidePillButton({
    required this.enabled,
    required this.text,
    required this.icon,
    required this.leading,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leading ??
                        Icon(
                          icon,
                          size: 15,
                          color: textColor,
                        ),
                    const SizedBox(width: 6),
                    Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: textColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final OwnerProject project;
  final String serverRootNoApi;
  final double size;
  final double radius;
  final Color band;

  const _AppIcon({
    required this.project,
    required this.serverRootNoApi,
    required this.size,
    required this.radius,
    required this.band,
  });

  String _abs(String? maybe) {
    if (maybe == null) return '';
    final s0 = maybe.trim();

    if (s0.isEmpty || s0.toLowerCase() == 'null') return '';
    if (s0.startsWith('http://') || s0.startsWith('https://')) {
      return Uri.parse(s0).toString();
    }
    if (s0.startsWith('//')) return Uri.parse('https:$s0').toString();

    final base = serverRootNoApi.replaceAll(RegExp(r'/+$'), '');
    final rel = s0.startsWith('/') ? s0 : '/$s0';
    return Uri.parse('$base$rel').toString();
  }

  @override
  Widget build(BuildContext context) {
    final rawLogo = project.logoUrl;
    final cleaned = (rawLogo ?? '').trim();

    if (cleaned.isNotEmpty && cleaned.toLowerCase() != 'null') {
      final baseSrc = _abs(cleaned);
      final src =
          '$baseSrc${baseSrc.contains('?') ? '&' : '?'}v=${project.linkId}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          src,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return Container(
              width: size,
              height: size,
              color: band.withOpacity(.10),
              alignment: Alignment.center,
              child: SizedBox(
                width: size * 0.33,
                height: size * 0.33,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _fallback(context),
        ),
      );
    }

    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final text =
        (project.appName.isNotEmpty ? project.appName : project.projectName)
            .trim();
    final initial = (text.isEmpty ? 'A' : text.characters.first.toUpperCase());

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: band.withOpacity(.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;

  const _StatusPill({
    required this.label,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.40)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: small ? 9 : 10.5,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniPill({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _TestFlightLikeIcon extends StatelessWidget {
  final double size;
  const _TestFlightLikeIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1FB2FF), Color(0xFF0A74FF)],
            ),
          ),
          child: CustomPaint(
            painter: _TestFlightPainter(),
          ),
        ),
      ),
    );
  }
}

class _TestFlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final c = Offset(w / 2, h / 2);

    final grid = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = w * 0.06;

    for (int i = 1; i <= 2; i++) {
      final x = w * i / 3;
      final y = h * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    final glow = Paint()..color = Colors.white.withOpacity(0.18);
    canvas.drawCircle(c, w * 0.42, glow);

    final blade = Paint()..color = Colors.white.withOpacity(0.90);

    void bladeAt(double angle) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);

      final bw = w * 0.16;
      final bl = w * 0.38;
      final rect = Rect.fromCenter(
        center: Offset(0, -w * 0.30),
        width: bw,
        height: bl,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(bw)),
        blade,
      );

      canvas.restore();
    }

    bladeAt(0);
    bladeAt(2.09439510239);
    bladeAt(4.18879020479);

    final hub = Paint()..color = Colors.white.withOpacity(0.95);
    canvas.drawCircle(c, w * 0.07, hub);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}