import '../../data/models/social_channel.dart';

/// Single-state object pattern (matches existing cubits in this repo).
class SocialChannelsState {
  final bool loading;
  final bool mutating;
  final List<SocialChannel> channels;
  final String? error;
  final String? infoMessage;

  const SocialChannelsState({
    this.loading = false,
    this.mutating = false,
    this.channels = const [],
    this.error,
    this.infoMessage,
  });

  const SocialChannelsState.initial() : this();

  SocialChannelsState copyWith({
    bool? loading,
    bool? mutating,
    List<SocialChannel>? channels,
    String? error,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) =>
      SocialChannelsState(
        loading:     loading  ?? this.loading,
        mutating:    mutating ?? this.mutating,
        channels:    channels ?? this.channels,
        error:       clearError ? null : (error ?? this.error),
        infoMessage: clearInfo  ? null : (infoMessage ?? this.infoMessage),
      );
}
