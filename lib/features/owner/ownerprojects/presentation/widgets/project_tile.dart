import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
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

  String _abs(String? maybe) {
    if (maybe == null || maybe.isEmpty) return '';
    final s = maybe.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = serverRootNoApi.replaceAll(RegExp(r'/+$'), '');
    final rel = s.startsWith('/') ? s : '/$s';
    return '$base$rel';
  }

  Future<void> _openUrl(BuildContext context, String urlStr) async {
    if (urlStr.trim().isEmpty) return;
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;

    if (!await canLaunchUrl(uri)) {
      AppToast.error(context, 'Cannot open: $urlStr');
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
    AppToast.success(context, 'Download started');
  }

  String _statusLabel() {
    final s = project.status.trim();
    if (s.isNotEmpty) return s;
    return project.isApkReady ? 'ACTIVE' : 'IN_PRODUCTION';
  }

  Color _statusColor(ColorScheme cs, String status) {
    final up = status.toUpperCase();
    if (up == 'ACTIVE') return cs.tertiary;
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

    final statusLabel = _statusLabel();
    final statusColor = _statusColor(cs, statusLabel);

    final apkUrl = _abs(project.apkUrl);
    final ipaUrl = _abs(project.ipaUrl);

    final androidReady = apkUrl.isNotEmpty;
    final iosReady = ipaUrl.isNotEmpty;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final bool tiny = w < 520;
        final double titleSize = tiny ? 16 : 18;
        final double subSize = tiny ? 11 : 12;
        final double pad = tiny ? 12 : 14;
        final double iconBox = tiny ? 48 : 54;
        final double iconSize = tiny ? 24 : 28;

        Widget fitted(Widget child, {Alignment align = Alignment.center}) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: align,
            child: child,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 10),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, tiny ? 10 : 12),
                child: Row(
                  children: [
                    _AppIcon(
                      project: project,
                      band: cs.primary,
                      serverRootNoApi: serverRootNoApi,
                      size: tiny ? 56 : 62,
                      radius: tiny ? 16 : 18,
                      fontSize: tiny ? 20 : 22,
                    ),
                    const SizedBox(width: 12),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Pill(text: statusLabel, color: statusColor, tiny: tiny),
                    const SizedBox(width: 10),
                    fitted(
                      OutlinedButton.icon(
                        onPressed: androidReady
                            ? () => _openUrl(context, apkUrl)
                            : null,
                        icon: Icon(Icons.science_rounded, size: tiny ? 16 : 18),
                        label: Text(
                          l10n.owner_projects_test,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: tiny ? 11 : 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: tiny ? 12 : 14,
                            vertical: tiny ? 10 : 12,
                          ),
                        ),
                      ),
                      align: Alignment.centerRight,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outlineVariant.withOpacity(.6)),
              Padding(
                padding: EdgeInsets.all(pad),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _PlatformPanel(
                          compact: tiny,
                          title: 'Android',
                          icon: Icons.android_rounded,
                          iconBox: iconBox,
                          iconSize: iconSize,
                          ready: androidReady,
                          storeLine: 'Play Store: Not Requested',
                          primaryColor: cs.primary,
                          downloadLabel: 'APK',
                          downloadUrl: apkUrl,
                          publishLabel: l10n.owner_publish_request_play,
                          onPublish: () => PublishWizardDialog.open(
                            context,
                            api: publishApi,
                            aupId: project.linkId,
                            appName: appName,
                            platform: PublishPlatform.android,
                            store: PublishStore.playStore,
                          ),
                          onDownload: (u) => _openUrl(context, u),
                        ),
                      ),
                      VerticalDivider(
                        width: tiny ? 18 : 28,
                        thickness: 1,
                        color: cs.outlineVariant.withOpacity(.6),
                      ),
                      Expanded(
                        child: _PlatformPanel(
                          compact: tiny,
                          title: 'iOS',
                          icon: Icons.apple_rounded,
                          iconBox: iconBox,
                          iconSize: iconSize,
                          ready: iosReady,
                          storeLine: 'App Store: Not Requested',
                          primaryColor: cs.onSurface,
                          downloadLabel: 'IPA',
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
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final double labelSize = compact ? 11 : 12;

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
                borderRadius: BorderRadius.circular(18),
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
                    text: ready ? 'Ready' : 'Building',
                    color: ready ? cs.primary : cs.tertiary,
                    tiny: compact,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: cs.outlineVariant.withOpacity(.6)),
        const SizedBox(height: 10),
        Text(
          storeLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(
            fontSize: compact ? 11 : 12,
            color: cs.onSurface.withOpacity(.7),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'DOWNLOAD',
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
                    borderRadius: BorderRadius.circular(14)),
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: compact ? 10 : 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'PUBLISH',
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
                    borderRadius: BorderRadius.circular(999)),
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: compact ? 10 : 12),
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
    if (maybe == null || maybe.isEmpty) return '';
    final s = maybe.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = serverRootNoApi.replaceAll(RegExp(r'/+$'), '');
    final rel = s.startsWith('/') ? s : '/$s';
    return '$base$rel';
  }

  @override
  Widget build(BuildContext context) {
    final logo = project.logoUrl;
    if (logo != null && logo.trim().isNotEmpty) {
      final src = _abs(logo);
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          src,
          width: size,
          height: size,
          fit: BoxFit.cover,
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
          horizontal: tiny ? 8 : 10, vertical: tiny ? 5 : 6),
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
