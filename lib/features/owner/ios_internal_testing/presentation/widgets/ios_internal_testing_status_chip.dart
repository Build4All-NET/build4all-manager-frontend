import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class IosInternalTestingStatusChip extends StatelessWidget {
  final String? status;
  final bool compact;

  const IosInternalTestingStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final normalized = (status ?? '').trim().toUpperCase();

    late final String label;
    late final Color fg;
    late final Color bg;
    late final IconData icon;

    switch (normalized) {
      case 'READY':
        label = l10n.iosInternalTestingStatusReady;
        fg = const Color(0xFF16A34A);
        bg = const Color(0xFF16A34A).withOpacity(.12);
        icon = Icons.verified_rounded;
        break;

      case 'WAITING_OWNER_ACCEPTANCE':
        label = l10n.iosInternalTestingStatusWaitingAcceptance;
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFD97706).withOpacity(.12);
        icon = Icons.schedule_rounded;
        break;

      case 'FAILED':
        label = l10n.iosInternalTestingStatusFailed;
        fg = cs.error;
        bg = cs.error.withOpacity(.12);
        icon = Icons.error_outline_rounded;
        break;

      case 'PROCESSING':
        label = l10n.iosInternalTestingStatusProcessing;
        fg = cs.primary;
        bg = cs.primary.withOpacity(.10);
        icon = Icons.sync_rounded;
        break;

      case 'REQUESTED':
        label = l10n.iosInternalTestingStatusRequested;
        fg = cs.secondary;
        bg = cs.secondary.withOpacity(.12);
        icon = Icons.send_rounded;
        break;

      case 'INVITED_TO_APPLE_TEAM':
        label = l10n.iosInternalTestingStatusInvitationSent;
        fg = cs.primary;
        bg = cs.primary.withOpacity(.10);
        icon = Icons.mail_outline_rounded;
        break;

      case 'ADDING_TO_INTERNAL_TESTING':
        label = l10n.iosInternalTestingStatusFinalizing;
        fg = cs.primary;
        bg = cs.primary.withOpacity(.10);
        icon = Icons.settings_rounded;
        break;

      case 'CANCELLED':
        label = l10n.iosInternalTestingStatusCancelled;
        fg = cs.outline;
        bg = cs.surfaceContainerHighest;
        icon = Icons.block_rounded;
        break;

      default:
        label = l10n.iosInternalTestingStatusNotRequested;
        fg = cs.outline;
        bg = cs.surfaceContainerHighest;
        icon = Icons.ios_share_rounded;
    }

    final vertical = compact ? 6.0 : 8.0;
    final horizontal = compact ? 10.0 : 12.0;
    final iconSize = compact ? 15.0 : 16.0;
    final fontSize = compact ? 11.5 : 12.5;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: fg.withOpacity(.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: tt.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}