import '../../data/models/social_channel.dart';
import '../../data/models/social_post.dart';

/// State for the per-item social panel: every active feed-capable channel
/// the tenant has, optionally with a per-item override, plus the most recent
/// posts for the item across all channels.
class ItemSocialState {
  final bool loading;
  final bool mutating;
  final List<SocialChannel> channels;
  final Map<int, SocialItemOverride> overridesByChannelId;
  final List<SocialPost> recentPosts;
  final String? error;
  final String? infoMessage;

  const ItemSocialState({
    this.loading = false,
    this.mutating = false,
    this.channels = const [],
    this.overridesByChannelId = const {},
    this.recentPosts = const [],
    this.error,
    this.infoMessage,
  });

  const ItemSocialState.initial() : this();

  ItemSocialState copyWith({
    bool? loading,
    bool? mutating,
    List<SocialChannel>? channels,
    Map<int, SocialItemOverride>? overridesByChannelId,
    List<SocialPost>? recentPosts,
    String? error,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) =>
      ItemSocialState(
        loading: loading ?? this.loading,
        mutating: mutating ?? this.mutating,
        channels: channels ?? this.channels,
        overridesByChannelId: overridesByChannelId ?? this.overridesByChannelId,
        recentPosts: recentPosts ?? this.recentPosts,
        error:       clearError ? null : (error ?? this.error),
        infoMessage: clearInfo  ? null : (infoMessage ?? this.infoMessage),
      );

  /// Effective auto-publish setting for a channel given the override map.
  /// null override means inherit channel.autoPublishEnabled.
  bool effectiveAutoPublish(SocialChannel channel) {
    final ov = overridesByChannelId[channel.id]?.autoPublishOverride;
    return ov ?? channel.autoPublishEnabled;
  }
}
