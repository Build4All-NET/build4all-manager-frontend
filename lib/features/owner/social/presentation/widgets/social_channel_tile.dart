import 'package:flutter/material.dart';

import '../../data/models/social_channel.dart';

/// Card representing one connected channel. Shows provider badge, name,
/// status pill, last sync, and the auto-publish toggle. Tap to open detail.
class SocialChannelTile extends StatelessWidget {
  final SocialChannel channel;
  final VoidCallback onTap;
  final ValueChanged<bool> onAutoPublishChanged;

  const SocialChannelTile({
    super.key,
    required this.channel,
    required this.onTap,
    required this.onAutoPublishChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: _ProviderBadge(provider: channel.provider, color: scheme.primary),
        title: Text(
          channel.externalAccountName?.isNotEmpty == true
              ? channel.externalAccountName!
              : channel.externalAccountId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(channel.provider.displayName,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline)),
            const SizedBox(height: 6),
            Row(children: [
              _StatusPill(status: channel.status),
              const SizedBox(width: 8),
              if (channel.lastError != null)
                Icon(Icons.warning_amber_rounded, size: 16, color: scheme.error),
            ]),
          ],
        ),
        trailing: Switch(
          value: channel.autoPublishEnabled,
          onChanged: channel.status == SocialChannelStatus.active
              ? onAutoPublishChanged
              : null,
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _ProviderBadge extends StatelessWidget {
  final SocialChannelProvider provider;
  final Color color;
  const _ProviderBadge({required this.provider, required this.color});

  IconData get _icon {
    switch (provider) {
      case SocialChannelProvider.facebookPage:    return Icons.facebook;
      case SocialChannelProvider.instagram:       return Icons.photo_camera_outlined;
      case SocialChannelProvider.metaCatalog:     return Icons.storefront_outlined;
      case SocialChannelProvider.whatsappCatalog: return Icons.chat_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.12),
      foregroundColor: color,
      child: Icon(_icon),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final SocialChannelStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      SocialChannelStatus.active       => ('Active',        scheme.primary),
      SocialChannelStatus.disabled     => ('Disabled',      scheme.outline),
      SocialChannelStatus.tokenExpired => ('Token expired', scheme.error),
      SocialChannelStatus.revoked      => ('Revoked',       scheme.error),
      SocialChannelStatus.error        => ('Error',         scheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}
