// lib/features/owner/ownerprofile/presentation/widgets/profile_info_card.dart

import 'package:build4all_manager/features/owner/ownerprofile/domain/entities/owner_profile.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileInfoCard extends StatelessWidget {
  final OwnerProfile p;
  const ProfileInfoCard({super.key, required this.p});

  Future<void> _copy(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context)!;
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: cleaned));
    if (!context.mounted) return;
    AppToast.success(context, l10n.copied ?? 'Copied');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    Widget row({
      required IconData icon,
      required String label,
      required String value,
      Color? tint,
      Widget? trailing,
    }) {
      final color = tint ?? cs.primary;

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          label,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: trailing,
      );
    }

    final email = p.email.trim();
    final phone = (p.phoneNumber ?? '').trim();

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(
                  l10n.owner_nav_profile,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(.7)),

          // ✅ Email ONCE
          row(
            icon: Icons.mail_outline_rounded,
            label: l10n.owner_profile_email,
            value: email,
            trailing: email.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.common_copy,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => _copy(context, email),
                  ),
          ),
          const Divider(indent: 72, endIndent: 12),

          // ✅ Phone
          row(
            icon: Icons.phone_outlined,
            label: l10n.owner_profile_phone,
            value: phone,
            trailing: phone.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.common_copy,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => _copy(context, phone),
                  ),
          ),
          const Divider(indent: 72, endIndent: 12),

          // ✅ Full name
          row(
            icon: Icons.person_outline_rounded,
            label: l10n.owner_profile_name,
            value: p.fullName.trim(),
          ),
          const Divider(indent: 72, endIndent: 12),

          // ✅ Username
          row(
            icon: Icons.alternate_email_rounded,
            label: l10n.owner_profile_username ?? 'Username',
            value: p.username.trim(),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
