import 'package:build4all_manager/features/owner/common/domain/entities/owner_project.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/top_toast.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectTile extends StatelessWidget {
  final OwnerProject project;
  final String serverRootNoApi; // host without /api
  final Future<void> Function(OwnerProject p)? onRebuild;

  const ProjectTile({
    super.key,
    required this.project,
    required this.serverRootNoApi,
    this.onRebuild,
  });

  String _abs(String? maybe) {
    if (maybe == null || maybe.isEmpty) return '';
    final s = maybe.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = serverRootNoApi.replaceAll(RegExp(r'/+$'), '');
    final rel = s.startsWith('/') ? s : '/$s';
    return '$base$rel';
  }

  Future<void> _openApk(BuildContext context) async {
    final urlStr = _abs(project.apkUrl);
    if (urlStr.isEmpty) return;
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;

    if (!await canLaunchUrl(uri)) {
      showTopToast(
        context,
        'Cannot open: $urlStr',
        type: ToastType.error,
        haptics: true,
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    showTopToast(context, 'Download started', type: ToastType.success);
  }

  Widget _logoChip(BuildContext context, Color band) {
    const double radius = 14.0;
    const double size = 48.0;
    final logo = project.logoUrl;
    if (logo != null && logo.trim().isNotEmpty) {
      final src = _abs(logo);
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          color: band.withOpacity(.05),
          child: Image.network(
            src,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialAvatar(band),
          ),
        ),
      );
    }
    return _initialAvatar(band);
  }

  Widget _initialAvatar(Color band) {
    final text =
        (project.appName.isNotEmpty ? project.appName : project.projectName)
            .trim();
    final initial = (text.isEmpty ? 'A' : text.characters.first.toUpperCase());
    const double size = 48;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: band.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final ready = project.isApkReady;
    final band = ready ? cs.primary : cs.tertiary;
    final statusLabel = project.status.isEmpty
        ? (ready ? 'ACTIVE' : 'IN_PRODUCTION')
        : project.status;

    return LayoutBuilder(
      builder: (context, c) {
        final double w = c.maxWidth;

        // only stack actions on super narrow widths
        final bool compactActions = w < 420;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // ✅ Flexible banner height (title can wrap)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [band.withOpacity(.18), band.withOpacity(.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    _logoChip(context, band),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TitleBlock(
                        appName: (project.appName.isNotEmpty
                            ? project.appName
                            : project.projectName),
                        slug: project.slug,
                        statusLabel: statusLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(
                      ready: ready,
                      text: ready
                          ? l10n.owner_projects_ready
                          : l10n.owner_projects_building,
                      color: ready ? cs.primary : cs.tertiary,
                    ),
                    const SizedBox(height: 12),
                    _ActionsRow(
                      compact: compactActions,
                      ready: ready,
                      onOpen: () => _openApk(context),
                      onRebuild: (onRebuild == null)
                          ? null
                          : () async {
                              await onRebuild!(project);
                              if (context.mounted) {
                                showTopToast(context, 'Rebuild queued',
                                    type: ToastType.info);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final String appName;
  final String slug;
  final String statusLabel;

  const _TitleBlock({
    required this.appName,
    required this.slug,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Wrap title (2 lines)
        Text(
          appName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          '$slug · $statusLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.65)),
        ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final bool compact;
  final bool ready;
  final VoidCallback? onOpen;
  final VoidCallback? onRebuild;

  const _ActionsRow({
    required this.compact,
    required this.ready,
    required this.onOpen,
    required this.onRebuild,
  });

  Widget _openBtn(BuildContext context, {required bool stretch}) {
    final cs = Theme.of(context).colorScheme;

    final btn = TextButton.icon(
      onPressed: ready ? onOpen : null,
      icon: const Icon(Icons.download_rounded, size: 18),
      label: const Text('Open', maxLines: 1),
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
    );

    if (stretch) return SizedBox(width: double.infinity, child: btn);
    return Expanded(child: btn);
  }

  Widget _rebuildBtn(BuildContext context, {required bool stretch}) {
    final btn = OutlinedButton.icon(
      onPressed: onRebuild,
      icon: const Icon(Icons.build_rounded, size: 18),
      label: const Text('Rebuild', maxLines: 1),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
    );

    if (stretch) return SizedBox(width: double.infinity, child: btn);
    return Expanded(child: btn);
  }

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return Row(
        children: [
          _openBtn(context, stretch: false),
          const SizedBox(width: 8),
          _rebuildBtn(context, stretch: false),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _openBtn(context, stretch: true),
        const SizedBox(height: 8),
        _rebuildBtn(context, stretch: true),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool ready;
  final String text;
  final Color color;

  const _StatusPill({
    required this.ready,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
