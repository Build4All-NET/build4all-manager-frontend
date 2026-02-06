// lib/features/owner/ownerprojects/presentation/widgets/project_tile.dart
//
// ✅ Same UI/behavior — just **MORE compact**
// - Smaller paddings, radii, font sizes, button heights, icon sizes
// - Keeps: header layout, 2 cards side-by-side, no overflow, same logic

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
      AppToast.error(context, '${l10n.owner_project_err_cannot_open}: $cleaned');
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

  String _statusLabel() {
    final raw = project.status.trim();
    final low = raw.toLowerCase();
    if (raw.isEmpty || low == 'null') return 'UNKNOWN';
    if (low.split(RegExp(r'\s+')).first == 'active') return 'test';
    return raw;
  }

  Color _statusColor(ColorScheme cs, String label) {
    final low = label.toLowerCase();
    if (low == 'unknown') return cs.outline;
    if (low.contains('fail') || low.contains('error') || low.contains('reject')) {
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

    final appName = project.appName.isNotEmpty ? project.appName : project.projectName;

    final statusLabel = _statusLabel();
    final statusColor = _statusColor(cs, statusLabel);

    // Android
    final apkUrl = _abs(project.apkUrl);
    final bundleUrl = _abs(project.bundleUrl);
    final androidUrl = apkUrl.isNotEmpty ? apkUrl : bundleUrl;
    final androidReady = androidUrl.isNotEmpty;

    // iOS
    final iosUrl = _abs(project.ipaUrl);
    final iosReady = iosUrl.isNotEmpty;

    final androidShareLabel = l10n.owner_project_share_android(
      appName,
      apkUrl.isNotEmpty ? l10n.owner_project_apk : l10n.owner_project_aab,
    );
    final iosShareLabel = l10n.owner_project_share_ios(appName);

    final idLine = project.packageOrBundleId;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;

        // ✅ EXTRA compact sizing knobs
        final bool small = w < 360;
        final double pad = small ? 8 : 10; // smaller
        final double headerPad = small ? 10 : 12; // smaller
        final double gap = small ? 6 : 8;

        final double cardGap = small ? 8 : 10;
        final double eachCardW =
            ((w - (pad * 2) - cardGap) / 2).clamp(135.0, 600.0);

        final headerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF7F7F7),
            Colors.white,
            Colors.grey.shade100,
          ],
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
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
              // HEADER
              Container(
                decoration: BoxDecoration(gradient: headerGradient),
                child: Padding(
                  padding: EdgeInsets.all(headerPad),
                  child: Row(
                    children: [
                      _AppIcon(
                        project: project,
                        serverRootNoApi: serverRootNoApi,
                        size: small ? 40 : 44,
                        radius: 12,
                        band: cs.primary,
                      ),
                      const SizedBox(width: 8),
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
                                fontSize: small ? 15.5 : 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              project.slug,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface.withOpacity(.70),
                                fontWeight: FontWeight.w700,
                                fontSize: small ? 11.5 : 12.5,
                              ),
                            ),
                            if (idLine != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                idLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onSurface.withOpacity(.60),
                                  fontFamily: 'monospace',
                                  fontSize: small ? 11 : 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusPill(label: statusLabel, color: statusColor),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

              // TWO CARDS ROW
              Padding(
                padding: EdgeInsets.all(pad),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: eachCardW,
                        child: _PlatformCard(
                          maxW: eachCardW,
                          title: l10n.owner_project_android,
                          icon: Icons.android_rounded,
                          iconColor: const Color(0xFF22C55E),
                          statusText: androidReady
                              ? l10n.owner_project_ready
                              : l10n.owner_project_failed,
                          statusColor: androidReady
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          showErrorBox: false,
                          errorBoxText: '',
                          infoTitle: l10n.owner_project_play_store,
                          infoValue: l10n.owner_project_requested,
                          infoValueColor: const Color(0xFF1D4ED8),
                          enabledActions: androidUrl.isNotEmpty,
                         
                          onCopy: () => _copyLink(context, androidUrl),
                          onShare: () async {
                            final box = context.findRenderObject() as RenderBox?;
                            final rect =
                                box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
                            await _shareLink(context, androidUrl, androidShareLabel,
                                sharePositionOrigin: rect);
                          },
                          primaryText: l10n.common_download,
                          primaryIcon: Icons.download_rounded,
                          primaryEnabled: androidUrl.isNotEmpty,
                          onPrimary: () => _openUrl(context, androidUrl),
                          secondaryText: l10n.owner_project_requested,
                          secondaryIcon: Icons.upload_rounded,
                          secondaryEnabled: true,
                          onSecondary: () => PublishWizardDialog.open(
                            context,
                            api: publishApi,
                            aupId: project.linkId,
                            appName: appName,
                            platform: PublishPlatform.android,
                            store: PublishStore.playStore,
                            androidPackageName: project.androidPackageName,
                          ),
                        ),
                      ),
                      SizedBox(width: cardGap),
                      SizedBox(
                        width: eachCardW,
                        child: _PlatformCard(
                          maxW: eachCardW,
                          title: l10n.owner_project_ios,
                          icon: Icons.apple_rounded,
                          iconColor: const Color(0xFF2563EB),
                          statusText: iosReady
                              ? l10n.owner_project_ready
                              : l10n.owner_project_failed,
                          statusColor: iosReady
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          showErrorBox: false,
                          infoTitle: l10n.owner_project_app_store,
                          infoValue: iosReady
                              ? l10n.owner_project_requested
                              : l10n.owner_project_not_requested,
                          infoValueColor: iosReady
                              ? const Color(0xFF1D4ED8)
                              : cs.onSurface.withOpacity(.55),
                          enabledActions: iosUrl.isNotEmpty,
                          onCopy: () => _copyLink(context, iosUrl),
                          onShare: () async {
                            final box = context.findRenderObject() as RenderBox?;
                            final rect =
                                box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
                            await _shareLink(context, iosUrl, iosShareLabel,
                                sharePositionOrigin: rect);
                          },
                          primaryText: iosReady ? l10n.owner_project_open : l10n.owner_project_retry_build,
                          primaryIcon: iosReady ? Icons.open_in_new_rounded : Icons.refresh_rounded,
                          primaryEnabled: true,
                          onPrimary: () => _openUrl(context, iosUrl),
                          secondaryText: l10n.owner_project_requested,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: gap),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Platform Card — EXTRA compact
// ─────────────────────────────────────────────
class _PlatformCard extends StatelessWidget {
  final double maxW;

  final String title;
  final IconData icon;
  final Color iconColor;

  final String statusText;
  final Color statusColor;

  final String infoTitle;
  final String infoValue;
  final Color infoValueColor;

  final bool showErrorBox;
  final String errorBoxText;

  final bool enabledActions;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  final String primaryText;
  final IconData primaryIcon;
  final bool primaryEnabled;
  final VoidCallback onPrimary;

  final String secondaryText;
  final IconData secondaryIcon;
  final bool secondaryEnabled;
  final VoidCallback onSecondary;

  const _PlatformCard({
    required this.maxW,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.statusText,
    required this.statusColor,
    required this.infoTitle,
    required this.infoValue,
    required this.infoValueColor,
    required this.enabledActions,
    required this.onCopy,
    required this.onShare,
    required this.primaryText,
    required this.primaryIcon,
    required this.primaryEnabled,
    required this.onPrimary,
    required this.secondaryText,
    required this.secondaryIcon,
    required this.secondaryEnabled,
    required this.onSecondary,
    this.showErrorBox = false,
    this.errorBoxText = '',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bool tiny = maxW < 185;

    final double pad = tiny ? 8 : 9;
    final double btnH = tiny ? 34 : 36;
    final double iconBtnSize = tiny ? 34 : 36;

    final double valueMaxFont = tiny ? 18 : 20;
    final double titleFont = tiny ? 13.5 : 14.5;
    final double storeTitleFont = tiny ? 12.5 : 13.5;

    final double errorSlotH = tiny ? 34 : 38;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: tiny ? 17 : 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: titleFont,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          _MiniPill(text: statusText, color: statusColor),

          const SizedBox(height: 8),

          SizedBox(
            height: errorSlotH,
            child: showErrorBox
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7E7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFDC2626), size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorBoxText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                              fontSize: tiny ? 11.5 : 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 6),

          Text(
            '$infoTitle:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.bodyLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: storeTitleFont,
              color: cs.onSurface.withOpacity(.85),
            ),
          ),

          const SizedBox(height: 4),

          SizedBox(
            height: tiny ? 26 : 30,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  infoValue,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: infoValueColor,
                    fontSize: valueMaxFont,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: iconBtnSize,
                  child: _FadedSquareIcon(
                    enabled: enabledActions,
                    icon: Icons.copy_rounded,
                    onTap: onCopy,
                    iconSize: tiny ? 15 : 16,
                    radius: 10,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: SizedBox(
                  height: iconBtnSize,
                  child: _FadedSquareIcon(
                    enabled: enabledActions,
                    icon: Icons.share_rounded,
                    onTap: onShare,
                    iconSize: tiny ? 15 : 16,
                    radius: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: btnH,
            child: ElevatedButton.icon(
              onPressed: primaryEnabled ? onPrimary : null,
              icon: Icon(primaryIcon, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  primaryText,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.8),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B6BFF),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 7),

          SizedBox(
            width: double.infinity,
            height: btnH,
            child: OutlinedButton.icon(
              onPressed: secondaryEnabled ? onSecondary : null,
              icon: Icon(secondaryIcon, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  secondaryText,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.8),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(
                  color: Color(0xFF16A34A),
                  width: 2,
                ),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header Logo
// ─────────────────────────────────────────────
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
      final src = '$baseSrc${baseSrc.contains('?') ? '&' : '?'}v=${project.linkId}';

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
    final text = (project.appName.isNotEmpty ? project.appName : project.projectName).trim();
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

// ─────────────────────────────────────────────
// Pills + icon box — compact
// ─────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final shown = label.trim().toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.45)),
      ),
      child: Text(
        shown,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10.5,
          color: color,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FadedSquareIcon extends StatelessWidget {
  final bool enabled;
  final IconData icon;
  final VoidCallback onTap;

  final double iconSize;
  final double radius;

  const _FadedSquareIcon({
    required this.enabled,
    required this.icon,
    required this.onTap,
    this.iconSize = 16,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : .35,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: cs.outlineVariant.withOpacity(.7)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: const Color(0xFF0B6BFF), size: iconSize),
          ),
        ),
      ),
    );
  }
}
