import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';
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

  const ProjectTile({
    super.key,
    required this.project,
    required this.serverRootNoApi,
    required this.publishApi,
  });

  // ✅ makes relative urls absolute + handles "null" + //domain + encoding
  String _abs(String? maybe) {
    if (maybe == null) return '';
    final s0 = maybe.trim();
    if (s0.isEmpty || s0.toLowerCase() == 'null') return '';

    // already absolute
    if (s0.startsWith('http://') || s0.startsWith('https://')) {
      return Uri.parse(s0).toString();
    }

    // handle //example.com/path
    if (s0.startsWith('//')) {
      return Uri.parse('https:$s0').toString();
    }

    // relative -> base + path
    final base = serverRootNoApi.replaceAll(RegExp(r'/+$'), '');
    final rel = s0.startsWith('/') ? s0 : '/$s0';
    final full = '$base$rel';

    // encode safely
    return Uri.parse(full).toString();
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
          context, '${l10n.owner_project_err_cannot_open}: $cleaned');
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
    String label, {
    Rect? sharePositionOrigin,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = url.trim();

    if (cleaned.isEmpty) {
      AppToast.error(context, l10n.owner_project_err_no_link_share);
      return;
    }

    try {
      await Share.share(
        '$label:\n$cleaned',
        subject: label,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      AppToast.error(context, l10n.owner_project_err_share_failed);
      debugPrint('Share error: $e');
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    final s = project.status.trim();
    if (s.isNotEmpty) return s;
    return (project.isApkReady)
        ? l10n.owner_project_status_active
        : l10n.owner_project_status_in_production;
  }

  Color _statusColor(ColorScheme cs, String status) {
    final up = status.toUpperCase();
    if (up == 'ACTIVE' || up.contains('ACTIVE')) return cs.tertiary;
    if (up.contains('REVIEW')) return cs.secondary;
    if (up.contains('PROD')) return cs.primary;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final appName =
        project.appName.isNotEmpty ? project.appName : project.projectName;

    final statusLabel = _statusLabel(l10n);
    final statusColor = _statusColor(cs, statusLabel);

    // ✅ Android can be APK or AAB (bundleUrl)
    final apkUrl = _abs(project.apkUrl);
    final bundleUrl = _abs(project.bundleUrl);
    final androidReady = apkUrl.isNotEmpty || bundleUrl.isNotEmpty;

    final androidDownloadUrl = apkUrl.isNotEmpty ? apkUrl : bundleUrl;
    final androidDownloadLabel =
        apkUrl.isNotEmpty ? l10n.owner_project_apk : l10n.owner_project_aab;

    // ✅ iOS
    final ipaUrl = _abs(project.ipaUrl);
    final iosReady = ipaUrl.isNotEmpty;

    final iosShareLabel = l10n.owner_project_share_ios(appName);
    final androidShareLabel =
        l10n.owner_project_share_android(appName, androidDownloadLabel);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final bool tiny = w < 520;
        final double titleSize = tiny ? 15.5 : 17.5;
        final double subSize = tiny ? 11 : 12;
        final double pad = tiny ? 10 : 12;

        final double iconBox = tiny ? 46 : 52;
        final double iconSize = tiny ? 24 : 28;

        Widget fitted(Widget child, {Alignment align = Alignment.center}) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: align,
            child: child,
          );
        }

        Widget buildTopActions({
          required bool enabled,
          required String url,
          required String shareLabel,
        }) {
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? () => _copyLink(context, url) : null,
                  icon: Icon(Icons.copy_rounded, size: tiny ? 16 : 18),
                  label: Text(
                    l10n.common_copy,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: tiny ? 11 : 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: tiny ? 9 : 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Builder(
                  builder: (btnCtx) {
                    return OutlinedButton.icon(
                      onPressed: enabled
                          ? () async {
                              final box =
                                  btnCtx.findRenderObject() as RenderBox?;
                              final rect = box == null
                                  ? null
                                  : (box.localToGlobal(Offset.zero) & box.size);

                              await _shareLink(
                                context,
                                url,
                                shareLabel,
                                sharePositionOrigin: rect,
                              );
                            }
                          : null,
                      icon: Icon(Icons.share_rounded, size: tiny ? 16 : 18),
                      label: Text(
                        l10n.common_share,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: tiny ? 11 : 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: tiny ? 9 : 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        final headerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceVariant.withOpacity(.55),
            cs.surface.withOpacity(1),
          ],
        );

        final idLine = project.packageOrBundleId;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(.60)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // HEADER
              Container(
                decoration: BoxDecoration(gradient: headerGradient),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, tiny ? 8 : 10),
                  child: Row(
                    children: [
                      _AppIcon(
                        project: project,
                        band: cs.primary,
                        serverRootNoApi: serverRootNoApi,
                        size: tiny ? 54 : 60,
                        radius: tiny ? 14 : 16,
                        fontSize: tiny ? 20 : 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                fontSize: titleSize,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '/${project.slug}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                fontSize: subSize,
                                color: cs.onSurface.withOpacity(.65),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (idLine != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                idLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  fontSize: subSize,
                                  color: cs.onSurface.withOpacity(.55),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(text: statusLabel, color: statusColor, tiny: true),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: cs.outlineVariant.withOpacity(.60)),

              Padding(
                padding: EdgeInsets.all(pad),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _PlatformPanel(
                          compact: tiny,
                          title: l10n.owner_project_android,
                          icon: Icons.android_rounded,
                          iconBox: iconBox,
                          iconSize: iconSize,
                          ready: androidReady,
                          storeLine: l10n.owner_project_play_not_requested,
                          primaryColor: cs.primary,
                          downloadLabel: androidDownloadLabel,
                          downloadUrl: androidDownloadUrl,
                          publishLabel: l10n.owner_publish_request_play,
                          onPublish: () => PublishWizardDialog.open(
                            context,
                            api: publishApi,
                            aupId: project.linkId,
                            appName: appName,
                            platform: PublishPlatform.android,
                            store: PublishStore.playStore,
                          ),
                          topActions: buildTopActions(
                            enabled: androidDownloadUrl.isNotEmpty,
                            url: androidDownloadUrl,
                            shareLabel: androidShareLabel,
                          ),
                          onDownload: (u) => _openUrl(context, u),
                        ),
                      ),
                      VerticalDivider(
                        width: tiny ? 12 : 18,
                        thickness: 1,
                        color: cs.outlineVariant.withOpacity(.60),
                      ),
                      Expanded(
                        child: _PlatformPanel(
                          compact: tiny,
                          title: l10n.owner_project_ios,
                          icon: Icons.apple_rounded,
                          iconBox: iconBox,
                          iconSize: iconSize,
                          ready: iosReady,
                          storeLine: l10n.owner_project_appstore_not_requested,
                          primaryColor: cs.onSurface,
                          downloadLabel: l10n.owner_project_ipa,
                          downloadUrl: ipaUrl,
                          publishLabel: l10n.owner_publish_request_appstore,
                          onPublish: () => PublishWizardDialog.open(
                            context,
                            api: publishApi,
                            aupId: project.linkId,
                            appName: appName,
                            platform: PublishPlatform.ios,
                            store: PublishStore.appStore,
                          ),
                          topActions: buildTopActions(
                            enabled: ipaUrl.isNotEmpty,
                            url: ipaUrl,
                            shareLabel: iosShareLabel,
                          ),
                          onDownload: (u) => _openUrl(context, u),
                        ),
                      ),
                    ],
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

class _PlatformPanel extends StatelessWidget {
  final bool compact;

  final String title;
  final IconData icon;
  final double iconBox;
  final double iconSize;

  final bool ready;
  final String storeLine;
  final Color primaryColor;

  final String downloadLabel;
  final String downloadUrl;

  final String publishLabel;
  final VoidCallback onPublish;

  final Widget? topActions;
  final void Function(String url) onDownload;

  const _PlatformPanel({
    required this.compact,
    required this.title,
    required this.icon,
    required this.iconBox,
    required this.iconSize,
    required this.ready,
    required this.storeLine,
    required this.primaryColor,
    required this.downloadLabel,
    required this.downloadUrl,
    required this.publishLabel,
    required this.onPublish,
    required this.onDownload,
    required this.topActions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final double labelSize = compact ? 11 : 12;
    final double topActionsSlotH = compact ? 40 : 44;

    Widget fitted(Widget child) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: child,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: iconBox,
              height: iconBox,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: primaryColor, size: iconSize),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 13 : 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _Pill(
                    text: ready
                        ? l10n.owner_project_ready
                        : l10n.owner_project_building,
                    color: ready ? cs.primary : cs.tertiary,
                    tiny: compact,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: cs.outlineVariant.withOpacity(.60)),
        const SizedBox(height: 8),
        Text(
          storeLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(
            fontSize: compact ? 11 : 12,
            color: cs.onSurface.withOpacity(.7),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: topActionsSlotH,
          child: topActions ?? const SizedBox.shrink(),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.owner_project_download_section,
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 11 : 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: fitted(
            OutlinedButton.icon(
              onPressed:
                  downloadUrl.isEmpty ? null : () => onDownload(downloadUrl),
              icon: Icon(Icons.download_rounded, size: compact ? 16 : 18),
              label: Text(
                downloadLabel,
                style:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: labelSize),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: compact ? 9 : 10,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.owner_project_publish_section,
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 11 : 12,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: fitted(
            ElevatedButton.icon(
              onPressed: onPublish,
              icon: Icon(Icons.send_rounded, size: compact ? 16 : 18),
              label: Text(
                publishLabel,
                style:
                    TextStyle(fontWeight: FontWeight.w900, fontSize: labelSize),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: compact ? 9 : 10,
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppIcon extends StatelessWidget {
  final OwnerProject project;
  final Color band;
  final String serverRootNoApi;

  final double size;
  final double radius;
  final double fontSize;

  const _AppIcon({
    required this.project,
    required this.band,
    required this.serverRootNoApi,
    required this.size,
    required this.radius,
    required this.fontSize,
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
    final full = '$base$rel';

    return Uri.parse(full).toString();
  }

  @override
  Widget build(BuildContext context) {
    final rawLogo = project.logoUrl;
    final cleaned = (rawLogo ?? '').trim();

    if (cleaned.isNotEmpty && cleaned.toLowerCase() != 'null') {
      final baseSrc = _abs(cleaned);

      // ✅ stable cache-bust (not DateTime.now spam)
      final src =
          '$baseSrc${baseSrc.contains('?') ? '&' : '?'}v=${project.linkId}';

      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          src,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, err, __) {
            debugPrint('LOGO FAIL => $src | $err');
            return _fallback(context);
          },
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
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: fontSize),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final bool tiny;

  const _Pill({
    required this.text,
    required this.color,
    required this.tiny,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tiny ? 8 : 10,
        vertical: tiny ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: tiny ? 10 : 12,
          color: color,
        ),
      ),
    );
  }
}
