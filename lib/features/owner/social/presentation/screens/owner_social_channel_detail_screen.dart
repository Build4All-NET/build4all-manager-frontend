import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/social_channel.dart';
import '../cubit/social_channels_cubit.dart';
import '../cubit/social_channels_state.dart';

/// Detail / settings page for one connected channel. Reads the latest copy
/// of the channel from the parent cubit each rebuild — so external refreshes
/// reflect immediately. Mutations route back through the same cubit.
class OwnerSocialChannelDetailScreen extends StatelessWidget {
  /// The cubit lives in the parent route; we look it up via [BlocProvider.value]
  /// so this screen and the list share state.
  final SocialChannelsCubit cubit;
  final int channelId;

  const OwnerSocialChannelDetailScreen({
    super.key,
    required this.cubit,
    required this.channelId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: _Body(channelId: channelId),
    );
  }
}

class _Body extends StatefulWidget {
  final int channelId;
  const _Body({required this.channelId});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _captionController = TextEditingController();
  bool _captionDirty = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<SocialChannelsCubit, SocialChannelsState>(
      builder: (context, state) {
        final ch = state.channels.firstWhere(
          (c) => c.id == widget.channelId,
          orElse: () => _missingChannel(),
        );
        if (ch.id == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Channel')),
            body: const Center(child: Text('Channel not found')),
          );
        }

        // Sync the caption controller when the channel changes from elsewhere.
        if (!_captionDirty && _captionController.text != (ch.captionTemplate ?? '')) {
          _captionController.text = ch.captionTemplate ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(ch.externalAccountName?.isNotEmpty == true
                ? ch.externalAccountName!
                : ch.externalAccountId),
            actions: [
              IconButton(
                icon: const Icon(Icons.link_off),
                tooltip: 'Disconnect',
                onPressed: state.mutating ? null : () => _confirmDisconnect(context, ch),
              ),
            ],
          ),
          body: AbsorbPointer(
            absorbing: state.mutating,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MetaCard(channel: ch),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Auto-publish on product save'),
                  subtitle: Text(
                    ch.status == SocialChannelStatus.active
                        ? 'Every product create/update will queue a post here.'
                        : 'Channel is not active — toggle ignored.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline),
                  ),
                  value: ch.autoPublishEnabled,
                  onChanged: ch.status == SocialChannelStatus.active
                      ? (v) => context.read<SocialChannelsCubit>().setAutoPublish(ch, v)
                      : null,
                ),
                const Divider(height: 32),
                Text('Caption template',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Use {{name}}, {{price}}, {{description}} as placeholders.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  maxLines: 5,
                  maxLength: 2000,
                  onChanged: (_) => setState(() => _captionDirty = true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'New: {{name}} — {{price}}\n{{description}}',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _captionDirty
                        ? () async {
                            await context
                                .read<SocialChannelsCubit>()
                                .setCaptionTemplate(ch, _captionController.text);
                            setState(() => _captionDirty = false);
                          }
                        : null,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
                const Divider(height: 32),
                _StatusActions(channel: ch),
                if (ch.lastError != null) ...[
                  const SizedBox(height: 16),
                  _LastErrorPanel(message: ch.lastError!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDisconnect(BuildContext context, SocialChannel ch) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disconnect channel?'),
        content: Text(
          'This stops Build4All from posting to '
          '${ch.externalAccountName ?? ch.externalAccountId} and removes its '
          'configuration. Pending unposted items will be cancelled.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Disconnect')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<SocialChannelsCubit>().disconnect(ch);
      if (context.mounted) Navigator.of(context).maybePop();
    }
  }

  SocialChannel _missingChannel() => const SocialChannel(
        id: -1,
        provider: SocialChannelProvider.facebookPage,
        status: SocialChannelStatus.disabled,
        externalAccountId: '',
        autoPublishEnabled: false,
      );
}

class _MetaCard extends StatelessWidget {
  final SocialChannel channel;
  const _MetaCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(channel.provider.displayName, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Account: ${channel.externalAccountId}',
                style: theme.textTheme.bodySmall),
            if (channel.tokenExpiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Token expires: ${channel.tokenExpiresAt!.toLocal()}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            if (channel.tokenSuffix != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Token suffix: ${channel.tokenSuffix}',
                    style: theme.textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final SocialChannel channel;
  const _StatusActions({required this.channel});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SocialChannelsCubit>();
    return Wrap(
      spacing: 8,
      children: [
        if (channel.status == SocialChannelStatus.disabled)
          FilledButton(
              onPressed: () => cubit.setStatus(channel, SocialChannelStatus.active),
              child: const Text('Enable')),
        if (channel.status == SocialChannelStatus.active)
          OutlinedButton(
              onPressed: () => cubit.setStatus(channel, SocialChannelStatus.disabled),
              child: const Text('Disable')),
      ],
    );
  }
}

class _LastErrorPanel extends StatelessWidget {
  final String message;
  const _LastErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
