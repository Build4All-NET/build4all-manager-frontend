import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/social_channel.dart';
import '../../data/models/social_post.dart';
import '../cubit/item_social_cubit.dart';
import '../cubit/item_social_state.dart';

/// Embed this in the product create/edit screen. Lists each active
/// feed-capable channel with a per-item override toggle, a caption-override
/// field, and a "publish now" button. Below, the 5 most recent posts for
/// the item are shown with status pills and permalinks (when present).
class ItemSocialPanel extends StatelessWidget {
  final int itemId;
  const ItemSocialPanel({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ItemSocialCubit(itemId: itemId)..load(),
      child: const _PanelBody(),
    );
  }
}

class _PanelBody extends StatelessWidget {
  const _PanelBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ItemSocialCubit, ItemSocialState>(
      listenWhen: (a, b) => a.error != b.error || a.infoMessage != b.infoMessage,
      listener: (context, state) {
        final msg = state.error ?? state.infoMessage;
        if (msg == null) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor:
                state.error != null ? Theme.of(context).colorScheme.error : null,
          ));
        context.read<ItemSocialCubit>().clearMessage();
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        if (state.loading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.channels.isEmpty) {
          return _Empty();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Social media',
                    style: theme.textTheme.titleMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Choose which channels publish this product when it is saved.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline),
                ),
              ),
              for (final ch in state.channels)
                _ChannelRow(channel: ch, state: state),
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text('Recent posts', style: theme.textTheme.titleMedium),
              ),
              if (state.recentPosts.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'No posts yet for this product.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline),
                  ),
                ),
              for (final p in state.recentPosts.take(5))
                _PostRow(post: p),
            ],
          ),
        );
      },
    );
  }
}

class _ChannelRow extends StatefulWidget {
  final SocialChannel channel;
  final ItemSocialState state;
  const _ChannelRow({required this.channel, required this.state});

  @override
  State<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<_ChannelRow> {
  late final TextEditingController _caption;
  bool _captionDirty = false;
  bool _captionExpanded = false;

  @override
  void initState() {
    super.initState();
    final ov = widget.state.overridesByChannelId[widget.channel.id];
    _caption = TextEditingController(text: ov?.captionOverride ?? '');
  }

  @override
  void didUpdateWidget(covariant _ChannelRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ov = widget.state.overridesByChannelId[widget.channel.id];
    if (!_captionDirty && (_caption.text != (ov?.captionOverride ?? ''))) {
      _caption.text = ov?.captionOverride ?? '';
    }
  }

  @override
  void dispose() { _caption.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ov = widget.state.overridesByChannelId[widget.channel.id];
    final auto = widget.state.effectiveAutoPublish(widget.channel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                foregroundColor: theme.colorScheme.primary,
                child: Icon(_iconFor(widget.channel.provider), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.channel.externalAccountName?.isNotEmpty == true
                      ? widget.channel.externalAccountName!
                      : widget.channel.externalAccountId,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              // Per-item auto-publish: tri-state pull-down.
              _AutoPublishMenu(
                channelId: widget.channel.id,
                channelDefault: widget.channel.autoPublishEnabled,
                explicitOverride: ov?.autoPublishOverride,
                onChange: (v) => context
                    .read<ItemSocialCubit>()
                    .setAutoPublishOverride(widget.channel.id, v),
              ),
              IconButton(
                tooltip: 'Publish now',
                icon: const Icon(Icons.send_outlined),
                onPressed: widget.channel.status == SocialChannelStatus.active
                    ? () => context
                        .read<ItemSocialCubit>()
                        .publishNow(widget.channel.id)
                    : null,
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => setState(() => _captionExpanded = !_captionExpanded),
            icon: Icon(_captionExpanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_captionExpanded
                ? 'Hide caption override'
                : (ov?.captionOverride?.isNotEmpty == true
                    ? 'Edit caption override'
                    : 'Add caption override')),
          ),
          if (_captionExpanded) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _caption,
              maxLines: 4,
              maxLength: 2000,
              onChanged: (_) => setState(() => _captionDirty = true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText:
                    'Defaults to the channel template. Use {{name}}, {{price}}, {{description}}.',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _captionDirty
                    ? () async {
                        final cleaned = _caption.text.trim();
                        await context
                            .read<ItemSocialCubit>()
                            .setCaptionOverride(
                                widget.channel.id,
                                cleaned.isEmpty ? null : cleaned);
                        setState(() => _captionDirty = false);
                      }
                    : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save override'),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              auto
                  ? 'Will publish on save'
                  : 'Will NOT publish on save',
              style: theme.textTheme.bodySmall?.copyWith(
                color: auto
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
          ),
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

class _AutoPublishMenu extends StatelessWidget {
  final int channelId;
  final bool channelDefault;
  final bool? explicitOverride;
  final ValueChanged<bool?> onChange;

  const _AutoPublishMenu({
    required this.channelId,
    required this.channelDefault,
    required this.explicitOverride,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    if (explicitOverride == null) {
      label = channelDefault ? 'Auto (on)' : 'Auto (off)';
    } else if (explicitOverride == true) {
      label = 'Always';
    } else {
      label = 'Never';
    }
    return PopupMenuButton<_OvChoice>(
      tooltip: 'Auto-publish setting',
      onSelected: (c) {
        switch (c) {
          case _OvChoice.inherit: onChange(null);  break;
          case _OvChoice.force:   onChange(true);  break;
          case _OvChoice.skip:    onChange(false); break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: _OvChoice.inherit, child: Text('Inherit channel default')),
        PopupMenuItem(value: _OvChoice.force,   child: Text('Always publish')),
        PopupMenuItem(value: _OvChoice.skip,    child: Text('Never publish')),
      ],
      child: Chip(
        label: Text(label),
        labelStyle: theme.textTheme.labelSmall,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

enum _OvChoice { inherit, force, skip }

class _PostRow extends StatelessWidget {
  final SocialPost post;
  const _PostRow({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: _StatusDot(status: post.status),
      title: Text(post.channelName, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        post.status == SocialPostStatus.failed && post.errorMessage != null
            ? 'Failed: ${post.errorMessage}'
            : (post.externalPermalink ?? _statusLabel(post.status)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: post.attemptCount > 0
          ? Text('attempt ${post.attemptCount}/${post.maxAttempts}',
              style: theme.textTheme.labelSmall)
          : null,
    );
  }

  String _statusLabel(SocialPostStatus s) {
    switch (s) {
      case SocialPostStatus.pending:   return 'Queued — waiting for dispatcher';
      case SocialPostStatus.running:   return 'Publishing…';
      case SocialPostStatus.succeeded: return 'Published';
      case SocialPostStatus.failed:    return 'Failed';
      case SocialPostStatus.skipped:   return 'Skipped';
      case SocialPostStatus.cancelled: return 'Cancelled';
    }
  }
}

class _StatusDot extends StatelessWidget {
  final SocialPostStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color color;
    IconData icon;
    switch (status) {
      case SocialPostStatus.succeeded:
        color = scheme.primary; icon = Icons.check_circle; break;
      case SocialPostStatus.failed:
        color = scheme.error;   icon = Icons.error_outline; break;
      case SocialPostStatus.pending:
      case SocialPostStatus.running:
        color = scheme.outline; icon = Icons.schedule; break;
      case SocialPostStatus.skipped:
      case SocialPostStatus.cancelled:
        color = scheme.outline.withOpacity(0.6); icon = Icons.remove_circle_outline; break;
    }
    return Icon(icon, color: color);
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.share_outlined,
                color: theme.colorScheme.outline, size: 48),
            const SizedBox(height: 8),
            Text(
              'No feed-capable channels connected.\n'
              'Connect one from the Social media section.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
