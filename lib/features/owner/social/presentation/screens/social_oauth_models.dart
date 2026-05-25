import '../../data/models/social_channel.dart';

/// Arguments passed via go_router's `extra` to the OAuth WebView screen.
class SocialOAuthArgs {
  final SocialChannelProvider provider;
  final String authorizationUrl;
  final String stateToken;
  final String redirectUri;
  const SocialOAuthArgs({
    required this.provider,
    required this.authorizationUrl,
    required this.stateToken,
    required this.redirectUri,
  });
}

/// Result the WebView screen pops with on success.
class SocialOAuthResult {
  final String code;
  final String state;
  const SocialOAuthResult(this.code, this.state);
}
