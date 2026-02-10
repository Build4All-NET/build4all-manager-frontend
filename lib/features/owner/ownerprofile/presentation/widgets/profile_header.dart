// lib/features/owner/ownerprofile/presentation/widgets/profile_header.dart

import 'package:build4all_manager/features/owner/ownerprofile/domain/entities/owner_profile.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final OwnerProfile p;
  const ProfileHeader({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = (p.fullName.isEmpty ? p.username : p.fullName).trim();
    final handle = p.username.trim().isEmpty ? '' : '@${p.username.trim()}';

    final headerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Color.lerp(cs.surface, cs.primary, 0.14)!,
              Color.lerp(cs.surface, cs.primary, 0.07)!,
              Color.lerp(cs.surface, cs.secondary, 0.10)!,
            ]
          : [
              Color.lerp(cs.surface, Colors.white, 0.75)!,
              Color.lerp(cs.surface, cs.primary, 0.04)!,
              Color.lerp(cs.surface, cs.secondary, 0.03)!,
            ],
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withOpacity(.6)),
      ),
      child: Container(
        decoration: BoxDecoration(gradient: headerGradient),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: _AvatarStrip(name: name, handle: handle),
      ),
    );
  }
}

class _AvatarStrip extends StatelessWidget {
  final String name;
  final String handle;

  const _AvatarStrip({
    required this.name,
    required this.handle,
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
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: cs.primary,
        ),
      ),
    );

    return Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? '—' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (handle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
