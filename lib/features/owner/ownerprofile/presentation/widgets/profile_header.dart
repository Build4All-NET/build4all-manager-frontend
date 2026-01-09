// lib/features/owner/ownerprofile/presentation/widgets/profile_header.dart
import 'package:build4all_manager/features/owner/ownerprofile/domain/entities/owner_profile.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';
import 'package:build4all_manager/shared/widgets/app_toast.dart'; // ✅ common toast
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileHeader extends StatelessWidget {
  final OwnerProfile p;
  const ProfileHeader({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final name = (p.fullName.isEmpty ? p.username : p.fullName);
    final email = p.email;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withOpacity(.12),
              cs.primaryContainer.withOpacity(.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: _AvatarStrip(
          name: name,
          email: email,
          onCopyEmail: () async {
            await Clipboard.setData(ClipboardData(text: email));
            if (!context.mounted) return;

            // ✅ common toast instead of top_toast
            AppToast.success(context, l10n.copied ?? 'Copied');
          },
        ),
      ),
    );
  }
}

class _AvatarStrip extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onCopyEmail;

  const _AvatarStrip({
    required this.name,
    required this.email,
    required this.onCopyEmail,
  });

  String _initials(String s) {
    final parts =
        s.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final avatar = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(.10),
        border: Border.all(color: cs.primary.withOpacity(.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: cs.primary,
        ),
      ),
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Copy',
              onPressed: onCopyEmail,
              icon: const Icon(Icons.copy_rounded, size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(child: info),
      ],
    );
  }
}
