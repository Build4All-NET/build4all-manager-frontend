// lib/features/owner/ownerprojects/presentation/widgets/project_tile.dart

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

  /// ✅ ACTIVE => test (strict), NOT INACTIVE
  String _statusLabel() {
    final raw = project.status.trim();
    final low = raw.toLowerCase();

    if (raw.isEmpty || low == 'null') return 'UNKNOWN';

    // ✅ active only
    if (low.split(RegExp(r'\s+')).first == 'active') return 'test';

    return raw;
  }

  /// ✅ Color based on displayed label (after override)
  Color _statusColor(ColorScheme cs, String label) {
    final low = label.toLowerCase();

    if (low == 'unknown') return cs.outline;
    if (low.contains('fail') ||
        low.contains('error') ||
        low.contains('reject')) {
      return cs.error;
    }

    if (low.contains('test')) return cs.secondary;

    if (low.contains('review')) return cs.primary;
    if (low.contains('prod') || low.contains('production')) return cs.tertiary;
    if (low.contains('local')) return cs.outlineVariant;

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

    // ✅ Android can be APK or AAB (bundleUrl)
    final apkUrl = _abs(project.apkUrl);
    final bundleUrl = _abs(project.bundleUrl);
    final androidReady = apkUrl.isNotEmpty || bundleUrl.isNotEmpty;
    final androidDownloadUrl = apkUrl.isNotEmpty ? apkUrl : bundleUrl;

    // ✅ iOS
    final ipaUrl = _abs(project.ipaUrl);
    final iosReady = ipaUrl.isNotEmpty;

    final iosShareLabel = l10n.owner_project_share_ios(appName);
    final androidShareLabel = l10n.owner_project_share_android(
      appName,
      apkUrl.isNotEmpty ? l10n.owner_project_apk : l10n.owner_project_aab,
    );

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        final bool tiny = w < 520;
        final double titleSize = tiny ? 15.5 : 17.5;
        final double subSize = tiny ? 11 : 12;
        final double pad = tiny ? 10 : 12;

        final double iconBox = tiny ? 46 : 52;
        final double iconSize = tiny ? 24 : 28;

        Widget buildTopActions({
          required bool enabled,
          required String url,
          required String shareLabel,
        }) {
          // NOTE: height alignment is handled inside _PlatformPanel (fixed btnH)
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

        final isDark = Theme.of(context).brightness == Brightness.dark;

        // ✅ grey gradient readable in both themes
        final headerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 191, 191, 191),
            const Color.fromARGB(255, 238, 238, 238),
            Colors.grey.shade200,
          ],
          stops: const [0.0, 0.6, 1.0],
        );

        final titleColor =
            isDark ? Colors.white.withOpacity(.92) : Colors.grey.shade900;
        final subColor =
            isDark ? Colors.white.withOpacity(.72) : Colors.grey.shade700;
        final idColor =
            isDark ? Colors.white.withOpacity(.60) : Colors.grey.shade600;

        final idLine = project.packageOrBundleId;

        // ✅ l10n fallback for new texts (no need to add keys right now)
        final androidDownloadSectionTitle =
            '${l10n.owner_project_download_section}:';
        final iosDownloadSectionTitle = l10n.owner_project_download_section;

        // These 2 strings you asked:
        final iosTestFlightHint =
            'Install TestFlight to open the app'; // if you later add l10n key, replace
        final androidInstallHint =
            'Download to install:'; // if you later add l10n key, replace

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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(isDark ? .10 : .65),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(pad, pad, pad, tiny ? 8 : 10),
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
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '/${project.slug}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodySmall?.copyWith(
                                    fontSize: subSize,
                                    color: subColor,
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
                                      color: idColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Pill(
                              text: statusLabel,
                              color: statusColor,
                              tiny: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: cs.outlineVariant.withOpacity(.60)),

              // ✅ better bottom spacing + min height
              Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: tiny ? 220 : 240),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ANDROID
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

                            // ✅ per your request
                            downloadSectionTitle: androidInstallHint,
                            downloadButtonIcon:
                                const Icon(Icons.download_rounded),
                            downloadButtonText: '', // icon-only
                            downloadButtonAlign:
                                _DownloadAlign.start, // same align

                            downloadUrl: androidDownloadUrl,

                            publishLabel: l10n.owner_publish_request_play,
                            onPublish: () => PublishWizardDialog.open(
                              context,
                              api: publishApi,
                              aupId: project.linkId,
                              appName: appName,
                              platform: PublishPlatform.android,
                              store: PublishStore.playStore,
                              androidPackageName: project.androidPackageName,
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
                          width: tiny ? 14 : 22,
                          thickness: 1,
                          color: cs.outlineVariant.withOpacity(.60),
                        ),

                        // IOS
                        Expanded(
                          child: _PlatformPanel(
                            compact: tiny,
                            title: l10n.owner_project_ios,
                            icon: Icons.apple_rounded,
                            iconBox: iconBox,
                            iconSize: iconSize,
                            ready: iosReady,
                            storeLine:
                                l10n.owner_project_appstore_not_requested,
                            primaryColor: cs.onSurface,

                            // ✅ per your request
                            downloadSectionTitle: iosTestFlightHint,
                            downloadButtonIcon:
                                _TestFlightLikeIcon(size: tiny ? 20 : 22),
                            downloadButtonText: 'Open', // you asked "Open"
                            downloadButtonAlign:
                                _DownloadAlign.start, // same align

                            downloadUrl: ipaUrl,

                            publishLabel: l10n.owner_publish_request_appstore,
                            onPublish: () => PublishWizardDialog.open(
                              context,
                              api: publishApi,
                              aupId: project.linkId,
                              appName: appName,
                              platform: PublishPlatform.ios,
                              store: PublishStore.appStore,
                              iosBundleId: project.iosBundleId,
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
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _DownloadAlign { start, end }

class _PlatformPanel extends StatelessWidget {
  final bool compact;

  final String title;
  final IconData icon;
  final double iconBox;
  final double iconSize;

  final bool ready;
  final String storeLine;
  final Color primaryColor;

  final String downloadSectionTitle;
  final Widget downloadButtonIcon;
  final String downloadButtonText;
  final _DownloadAlign downloadButtonAlign;

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
    required this.downloadSectionTitle,
    required this.downloadButtonIcon,
    required this.downloadButtonText,
    required this.downloadButtonAlign,
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

    // ✅ ONE height for ALL buttons across Android & iOS
    final double btnH = compact ? 42 : 46;

    // ✅ FIX: reserve same vertical slots so Publish aligns perfectly
    final double oneLineSlotH = compact ? 18 : 20; // storeLine
    final double sectionTitleSlotH = compact ? 18 : 20; // section titles

    final double labelSize = compact ? 11 : 12;

    final double gap = compact ? 8 : 10;
    final double gapSm = compact ? 6 : 8;

    Widget fitted(Widget child) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: child,
        );

    Widget fixedOneLineSlot(String text, double height, TextStyle? style) {
      return SizedBox(
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      );
    }

    // ✅ Download button (fixed height)
    final downloadBtn = SizedBox(
      height: btnH,
      child: OutlinedButton(
        onPressed: downloadUrl.isEmpty ? null : () => onDownload(downloadUrl),
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: compact ? 18 : 20),
              child: downloadButtonIcon,
            ),
            if (downloadButtonText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                downloadButtonText,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: labelSize,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // ✅ Publish button (fixed height)
    final publishBtn = SizedBox(
      width: double.infinity,
      height: btnH,
      child: ElevatedButton.icon(
        onPressed: onPublish,
        icon: Icon(Icons.send_rounded, size: compact ? 16 : 18),
        label: Text(
          publishLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: labelSize),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          elevation: 0,
        ),
      ),
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
                  SizedBox(height: gapSm),
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

        SizedBox(height: gap),
        Divider(height: 1, color: cs.outlineVariant.withOpacity(.60)),
        SizedBox(height: gapSm),

        // ✅ same height both columns
        fixedOneLineSlot(
          storeLine,
          oneLineSlotH,
          tt.bodyMedium?.copyWith(
            fontSize: compact ? 11 : 12,
            color: cs.onSurface.withOpacity(.7),
          ),
        ),

        SizedBox(height: gap),

        // ✅ fixed so it matches between android/ios
        SizedBox(height: btnH, child: topActions ?? const SizedBox.shrink()),

        SizedBox(height: gap),

        // ✅ prevents iOS title wrapping => publish misalignment
        fixedOneLineSlot(
          downloadSectionTitle,
          sectionTitleSlotH,
          tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 11 : 12,
          ),
        ),

        SizedBox(height: gapSm),

        downloadButtonAlign == _DownloadAlign.end
            ? Row(children: [const Spacer(), fitted(downloadBtn)])
            : Row(children: [fitted(downloadBtn), const Spacer()]),

        SizedBox(height: gap),

        fixedOneLineSlot(
          l10n.owner_project_publish_section,
          sectionTitleSlotH,
          tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 11 : 12,
          ),
        ),

        SizedBox(height: gapSm),

        // ✅ now BOTH publish buttons are EXACTLY on same line
        publishBtn,
      ],
    );
  }
}

class _TestFlightLikeIcon extends StatelessWidget {
  final double size;
  const _TestFlightLikeIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1FB2FF), Color(0xFF0A74FF)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: CustomPaint(painter: _TestFlightPainter()),
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
    final r = w * 0.33;

    final grid = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = w * 0.04;

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
      final rect =
          Rect.fromCenter(center: Offset(0, -r), width: bw, height: bl);
      final rr = RRect.fromRectAndRadius(rect, Radius.circular(bw));
      canvas.drawRRect(rr, blade);

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
