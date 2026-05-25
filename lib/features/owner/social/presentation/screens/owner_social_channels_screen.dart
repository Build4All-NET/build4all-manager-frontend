import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/social_channels_cubit.dart';
import '../cubit/social_channels_state.dart';
import '../widgets/connect_channel_sheet.dart';
import '../widgets/social_channel_tile.dart';
import 'social_oauth_models.dart';

/// Main screen for the social-media feature: a list of connected channels
/// plus a "Connect" entry point that launches the OAuth WebView flow.
class OwnerSocialChannelsScreen extends StatelessWidget {
  const OwnerSocialChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SocialChannelsCubit()..load(),
      child: const _OwnerSocialChannelsView(),
    );
  }
}

class _OwnerSocialChannelsView extends StatelessWidget {
  const _OwnerSocialChannelsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social media'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SocialChannelsCubit>().load(),
          ),
        ],
      ),
      body: BlocConsumer<SocialChannelsCubit, SocialChannelsState>(
        listenWhen: (a, b) => a.error != b.error || a.infoMessage != b.infoMessage,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          if (state.error != null) {
            messenger
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text(state.error!),
                  backgroundColor: Theme.of(context).colorScheme.error));
            context.read<SocialChannelsCubit>().clearMessage();
          } else if (state.infoMessage != null) {
            messenger
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text(state.infoMessage!)));
            context.read<SocialChannelsCubit>().clearMessage();
          }
        },
        builder: (context, state) {
          if (state.loading && state.channels.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.channels.isEmpty) {
            return _EmptyState(
              onConnect: () => _openConnectSheet(context),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<SocialChannelsCubit>().load(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: state.channels.length,
              itemBuilder: (_, i) {
                final ch = state.channels[i];
                return SocialChannelTile(
                  channel: ch,
                  onTap: () => context.push('/owner/social/channels/${ch.id}',
                      extra: ch),
                  onAutoPublishChanged: (v) =>
                      context.read<SocialChannelsCubit>().setAutoPublish(ch, v),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (innerContext) => FloatingActionButton.extended(
          onPressed: () => _openConnectSheet(innerContext),
          icon: const Icon(Icons.add_link),
          label: const Text('Connect'),
        ),
      ),
    );
  }

  Future<void> _openConnectSheet(BuildContext context) async {
    final cubit = context.read<SocialChannelsCubit>();
    await ConnectChannelSheet.show(context, onPick: (provider) async {
      // The redirect URI is an app-internal URL our WebView listens for.
      const redirectUri = 'build4all://oauth/social/callback';
      try {
        final start = await cubit.beginOAuth(provider, redirectUri: redirectUri);
        if (!context.mounted) return;
        final result = await context.push<SocialOAuthResult>('/owner/social/oauth',
            extra: SocialOAuthArgs(
              provider: provider,
              authorizationUrl: start.authorizationUrl,
              stateToken: start.stateToken,
              redirectUri: redirectUri,
            ));
        if (result != null) {
          await cubit.completeOAuth(code: result.code, state: result.state);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    });
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onConnect;
  const _EmptyState({required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.share_outlined,
                size: 64, color: theme.colorScheme.primary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text('No channels yet',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Connect a Facebook Page, Instagram, or Catalog to start '
              'publishing your products automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onConnect,
              icon: const Icon(Icons.add_link),
              label: const Text('Connect a channel'),
            ),
          ],
        ),
      ),
    );
  }
}

