// lib/features/owner/ownerprofile/presentation/widgets/profile_info_card.dart
import 'package:build4all_manager/features/owner/ownerprofile/domain/entities/owner_profile.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ProfileInfoCard extends StatelessWidget {
  final OwnerProfile p;
  const ProfileInfoCard({super.key, required this.p});

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
      VoidCallback? onTap,
    }) {
      final color = tint ?? cs.primary;
      return ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(value.isEmpty ? '—' : value,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.owner_nav_profile,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
         row(
            icon: Icons.mail_outline_rounded,
            label: l10n.owner_profile_email,
            value: p.email,
          ),
          const Divider(indent: 72, endIndent: 12),
          row(
            icon: Icons.phone_outlined,
            label: l10n.owner_profile_phone,
            value: p.phoneNumber ?? '',
          ),
          const SizedBox(height: 8),

          row(
            icon: Icons.person_outline_rounded,
            label: l10n.owner_profile_name,
            value: p.fullName,
          ),
          const Divider(indent: 72, endIndent: 12),
          row(
            icon: Icons.mail_outline_rounded,
            label: l10n.owner_profile_email,
            value: p.email,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
