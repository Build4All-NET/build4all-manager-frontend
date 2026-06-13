import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/core/constants/app_links.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Open a ticket" card that opens the Build4All ticketing portal.
///
/// The link is a fixed front-end constant (see [AppLinks.ticketsUrl]); no
/// backend endpoint is required. Built from the shared Card/ListTile theme
/// used across the profile screen so it sits next to "Contact support".
class OpenTicketCard extends StatelessWidget {
  const OpenTicketCard({super.key});

  Future<void> _onTap(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final opened = await launchUrl(
        Uri.parse(AppLinks.ticketsUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!context.mounted) return;
      if (!opened) {
        AppToast.error(context, l10n.open_ticket_failed);
      }
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, l10n.open_ticket_failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => _onTap(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cs.primary.withOpacity(.12),
          child: Icon(
            Icons.confirmation_number_rounded,
            color: cs.primary,
            size: 18,
          ),
        ),
        title: AutoSizeText(
          l10n.open_ticket_title,
          maxLines: 1,
          minFontSize: 12,
          stepGranularity: 0.5,
          overflow: TextOverflow.ellipsis,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: AutoSizeText(
          l10n.open_ticket_subtitle,
          maxLines: 2,
          minFontSize: 11,
          stepGranularity: 0.5,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.open_in_new_rounded,
          color: cs.primary,
        ),
      ),
    );
  }
}
