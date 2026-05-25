import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/social_api.dart';

/// Tile rendered on the catalog channel detail screen offering the
/// OWNER a way to fetch + copy the Plan B feed URL Meta can pull on
/// a schedule.
///
/// The URL expires server-side (default 30 days); the tile shows the
/// expiry and lets the OWNER re-issue at any time.
class PlanBFeedTile extends StatefulWidget {
  final SocialApi api;
  const PlanBFeedTile({super.key, required this.api});

  @override
  State<PlanBFeedTile> createState() => _PlanBFeedTileState();
}

class _PlanBFeedTileState extends State<PlanBFeedTile> {
  PlanBFeedUrl? _url;
  bool _loading = false;
  String? _error;

  Future<void> _issue() async {
    setState(() { _loading = true; _error = null; });
    try {
      final u = await widget.api.issueCatalogFeedUrl();
      if (!mounted) return;
      setState(() { _url = u; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _copy() async {
    if (_url == null) return;
    await Clipboard.setData(ClipboardData(text: _url!.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Feed URL copied')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.cloud_download_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Plan B: catalog pull feed',
                  style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 6),
            Text(
              'A signed URL Meta can pull on a schedule when our push is offline. '
              'Paste it into Meta Commerce Manager → Data Sources → Add Feed.',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
            if (_url == null)
              FilledButton.icon(
                onPressed: _loading ? null : _issue,
                icon: _loading
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.vpn_key_outlined),
                label: const Text('Issue feed URL'),
              )
            else ...[
              SelectableText(_url!.url, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                'Expires ${_url!.expiresAt.toLocal()}',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: _loading ? null : _issue,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-issue'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
