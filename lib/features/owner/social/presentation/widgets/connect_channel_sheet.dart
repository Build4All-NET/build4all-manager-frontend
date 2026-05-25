import 'package:flutter/material.dart';

import '../../data/models/social_channel.dart';

/// Bottom-sheet picker: choose which provider to connect. The screen shows
/// this when the user taps "Connect channel".
class ConnectChannelSheet extends StatelessWidget {
  /// Called when the user picks a provider.
  final void Function(SocialChannelProvider) onPick;

  const ConnectChannelSheet({super.key, required this.onPick});

  static Future<void> show(BuildContext context,
      {required void Function(SocialChannelProvider) onPick}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      builder: (_) => ConnectChannelSheet(onPick: onPick),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Text('Connect a channel', style: theme.textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Pick where Build4All should post your products.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          for (final p in SocialChannelProvider.values)
            ListTile(
              leading: Icon(_iconFor(p)),
              title: Text(p.displayName),
              onTap: () { Navigator.of(context).pop(); onPick(p); },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _iconFor(SocialChannelProvider p) {
    switch (p) {
      case SocialChannelProvider.facebookPage:    return Icons.facebook;
      case SocialChannelProvider.instagram:       return Icons.photo_camera_outlined;
      case SocialChannelProvider.metaCatalog:     return Icons.storefront_outlined;
      case SocialChannelProvider.whatsappCatalog: return Icons.chat_outlined;
    }
  }
}
