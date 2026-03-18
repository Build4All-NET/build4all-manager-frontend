import 'package:flutter/material.dart';

import 'package:build4all_manager/shared/themes/app_theme.dart';
import 'package:build4all_manager/features/owner/ios_internal_testing/presentation/widgets/ios_internal_testing_status_chip.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';

import '../../data/models/super_admin_ios_internal_testing_request_model.dart';

class SuperAdminIosInternalTestingRequestCard extends StatelessWidget {
  final SuperAdminIosInternalTestingRequestModel request;
  final bool acting;
  final bool showAppTitle;
  final VoidCallback onProcess;
  final VoidCallback onSync;
  final VoidCallback onMore;

  const SuperAdminIosInternalTestingRequestCard({
    super.key,
    required this.request,
    required this.acting,
    required this.onProcess,
    required this.onSync,
    required this.onMore,
    this.showAppTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<UiTokens>();
    final l10n = AppLocalizations.of(context)!;

    final borderColor = request.isFailed
        ? cs.error.withOpacity(.22)
        : cs.outlineVariant.withOpacity(.25);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens?.radiusLg ?? 16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAppTitle) ...[
            Text(
              request.appNameSnapshot.isNotEmpty
                  ? request.appNameSnapshot
                  : l10n.super_ios_internal_testing_unnamed_app,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IosInternalTestingStatusChip(
                status: request.status,
                compact: true,
              ),
              _TinyPill(
                icon: Icons.confirmation_number_outlined,
                text: '#${request.id}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.apps_rounded,
            text: request.bundleIdSnapshot,
            monospace: true,
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.mail_outline_rounded,
            text: request.appleEmail,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyPill(
                icon: Icons.person_outline_rounded,
                text: request.fullName,
              ),
              _TinyPill(
                icon: Icons.link_rounded,
                text: 'AUP ${request.ownerProjectLinkId}',
              ),
            ],
          ),
          if ((request.lastError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: request.isFailed
                    ? cs.error.withOpacity(.07)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: request.isFailed
                      ? cs.error.withOpacity(.16)
                      : cs.outlineVariant.withOpacity(.22),
                ),
              ),
              child: Text(
                request.lastError!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(.88),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _CompactActions(
            acting: acting,
            onProcess: onProcess,
            onSync: onSync,
            onMore: onMore,
          ),
        ],
      ),
    );
  }
}

class _CompactActions extends StatelessWidget {
  final bool acting;
  final VoidCallback onProcess;
  final VoidCallback onSync;
  final VoidCallback onMore;

  const _CompactActions({
    required this.acting,
    required this.onProcess,
    required this.onSync,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 430;

        final processButton = SizedBox(
          height: 42,
          child: FilledButton.tonal(
            onPressed: acting ? null : onProcess,
            child: Text(
              acting
                  ? l10n.common_working
                  : l10n.super_ios_internal_testing_process,
            ),
          ),
        );

        final syncButton = SizedBox(
          height: 42,
          child: FilledButton.tonal(
            onPressed: acting ? null : onSync,
            child: Text(
              acting
                  ? l10n.common_working
                  : l10n.super_ios_internal_testing_sync,
            ),
          ),
        );

        final moreButton = SizedBox(
          height: 42,
          width: 42,
          child: IconButton.filledTonal(
            onPressed: acting ? null : onMore,
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: l10n.super_ios_internal_testing_more_actions,
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              processButton,
              const SizedBox(height: 8),
              syncButton,
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: moreButton,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: processButton),
            const SizedBox(width: 8),
            Expanded(child: syncButton),
            const SizedBox(width: 8),
            moreButton,
          ],
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool monospace;

  const _InfoLine({
    required this.icon,
    required this.text,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TinyPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withOpacity(.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}