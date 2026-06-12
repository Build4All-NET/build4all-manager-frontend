import 'package:auto_size_text/auto_size_text.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/support/support_contact_service.dart';
import 'package:build4all_manager/shared/support/whatsapp_launcher.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// "Contact support" card that opens a WhatsApp chat with the super admin.
///
/// The number is read from the SUPER_ADMIN profile via the backend, so there
/// is no extra screen to configure it. Built from the shared Card/ListTile
/// theme used across the profile screen.
class ContactSupportCard extends StatefulWidget {
  final Dio dio;

  const ContactSupportCard({
    super.key,
    required this.dio,
  });

  @override
  State<ContactSupportCard> createState() => _ContactSupportCardState();
}

class _ContactSupportCardState extends State<ContactSupportCard> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _loading = true);

    try {
      final number =
          await SupportContactService(widget.dio).fetchSupportNumber();

      if (!mounted) return;

      if (number == null) {
        AppToast.error(context, l10n.contact_support_unavailable);
        return;
      }

      final opened = await openWhatsApp(
        rawNumber: number,
        message: l10n.contact_support_message,
      );

      if (!mounted) return;
      if (!opened) {
        AppToast.error(context, l10n.contact_support_unavailable);
      }
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, l10n.contact_support_unavailable);
    } finally {
      if (mounted) setState(() => _loading = false);
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
        onTap: _loading ? null : _onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: cs.primary.withOpacity(.12),
          child: Icon(
            Icons.support_agent_rounded,
            color: cs.primary,
            size: 18,
          ),
        ),
        title: AutoSizeText(
          l10n.contact_support_title,
          maxLines: 1,
          minFontSize: 12,
          stepGranularity: 0.5,
          overflow: TextOverflow.ellipsis,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: AutoSizeText(
          l10n.contact_support_subtitle,
          maxLines: 2,
          minFontSize: 11,
          stepGranularity: 0.5,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        trailing: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.chat_rounded,
                color: cs.primary,
              ),
      ),
    );
  }
}
