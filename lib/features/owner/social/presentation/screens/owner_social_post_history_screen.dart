import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/social_channel.dart';
import '../../data/models/social_post.dart';
import '../../data/services/social_api.dart';

/// Post-history screen for one channel. The dedicated channel-history
/// endpoint lands in Slice 4; for Slice 3 this screen surfaces an empty
/// state directing the OWNER to the per-item panel embedded in the
/// product editor.
class OwnerSocialPostHistoryScreen extends StatefulWidget {
  final SocialChannel channel;
  const OwnerSocialPostHistoryScreen({super.key, required this.channel});

  @override
  State<OwnerSocialPostHistoryScreen> createState() =>
      _OwnerSocialPostHistoryScreenState();
}

class _OwnerSocialPostHistoryScreenState
    extends State<OwnerSocialPostHistoryScreen> {
  final SocialApi _api = SocialApi();
  late Future<List<SocialPost>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listChannelPosts(widget.channel.id);
  }

  void _refresh() {
    setState(() {
      _future = _api.listChannelPosts(widget.channel.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History: ${widget.channel.externalAccountName ?? widget.channel.externalAccountId}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<List<SocialPost>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final posts = snap.data ?? const [];
          if (posts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_outlined,
                        color: theme.colorScheme.outline, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'No posts yet for this channel.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async { _refresh(); await _future; },
            child: ListView.separated(
              itemCount: posts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _PostTile(post: posts[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final SocialPost post;
  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final permalink = post.externalPermalink;
    return ListTile(
      title: Text(post.channelName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.itemId != null)
            Text('Item #${post.itemId}', style: theme.textTheme.bodySmall),
          if (post.status == SocialPostStatus.failed && post.errorMessage != null)
            Text('Failed: ${post.errorMessage}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error)),
          if (permalink != null)
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(permalink),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 14),
              label: Text(permalink, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
      trailing: Text(post.status.name,
          style: theme.textTheme.labelSmall),
      isThreeLine: true,
    );
  }
}
