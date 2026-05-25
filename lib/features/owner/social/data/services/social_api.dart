import 'package:dio/dio.dart';

import 'package:build4all_manager/core/network/dio_client.dart';
import '../models/social_channel.dart';
import '../models/social_post.dart';

/// Thin Dio wrapper for the social-media module's REST surface.
///
/// All endpoints carry the Bearer token configured globally on [DioClient].
/// Per the backend contract the auth filter rejects non-Bearer / non-OWNER
/// callers, so this client does no client-side auth checks of its own.
class SocialApi {
  final Dio _dio;

  SocialApi({Dio? dio}) : _dio = dio ?? DioClient.ensure();

  // -------- channels --------

  Future<List<SocialChannel>> listChannels() async {
    final r = await _dio.get('/owner/social/channels');
    final raw = (r.data as List).cast<Map<String, dynamic>>();
    return raw.map(SocialChannel.fromJson).toList(growable: false);
  }

  Future<SocialChannel> getChannel(int id) async {
    final r = await _dio.get('/owner/social/channels/$id');
    return SocialChannel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<SocialChannel> updateChannel(
    int id, {
    bool? autoPublishEnabled,
    String? captionTemplate,
    SocialChannelStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (autoPublishEnabled != null) body['autoPublishEnabled'] = autoPublishEnabled;
    if (captionTemplate != null)    body['captionTemplate']    = captionTemplate;
    if (status != null) {
      if (!status.userSettable) {
        throw ArgumentError('Status ${status.wire} is system-managed');
      }
      body['status'] = status.wire;
    }
    final r = await _dio.patch('/owner/social/channels/$id', data: body);
    return SocialChannel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteChannel(int id) async {
    await _dio.delete('/owner/social/channels/$id');
  }

  // -------- OAuth --------

  /// Asks the backend to issue a state token and provider authorisation URL.
  /// Returns an object the caller can use to drive the WebView round-trip.
  Future<OAuthStart> startOAuth(
    SocialChannelProvider provider, {
    required String redirectUri,
  }) async {
    final r = await _dio.post(
      '/owner/social/oauth/${provider.wire}/start',
      queryParameters: {'redirectUri': redirectUri},
    );
    final j = r.data as Map<String, dynamic>;
    return OAuthStart(
      authorizationUrl: j['authorizationUrl'] as String,
      stateToken:       j['stateToken'] as String,
      expiresAt:        DateTime.parse(j['expiresAt'] as String),
    );
  }

  /// Exchange the provider-returned [code] + [state] for one or more
  /// connected channels.
  Future<List<SocialChannel>> completeOAuth({
    required String code,
    required String state,
  }) async {
    final r = await _dio.post(
      '/owner/social/oauth/callback',
      data: {'code': code, 'state': state},
    );
    final list = (r.data['connectedChannels'] as List).cast<Map<String, dynamic>>();
    return list.map(SocialChannel.fromJson).toList(growable: false);
  }

  // -------- per-item social: history + publish-now + overrides --------

  Future<List<SocialPost>> listItemPosts(int itemId) async {
    final r = await _dio.get('/owner/items/$itemId/social/posts');
    final raw = (r.data as List).cast<Map<String, dynamic>>();
    return raw.map(SocialPost.fromJson).toList(growable: false);
  }

  Future<SocialPost> publishNow(int itemId, int channelId) async {
    final r = await _dio.post(
      '/owner/items/$itemId/social/publish-now',
      queryParameters: {'channelId': channelId},
    );
    return SocialPost.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<SocialItemOverride>> listOverrides(int itemId) async {
    final r = await _dio.get('/owner/items/$itemId/social/overrides');
    final raw = (r.data as List).cast<Map<String, dynamic>>();
    return raw.map(SocialItemOverride.fromJson).toList(growable: false);
  }

  Future<SocialItemOverride> putOverride(
    int itemId,
    int channelId, {
    bool? autoPublishOverride,
    String? captionOverride,
  }) async {
    final r = await _dio.put(
      '/owner/items/$itemId/social/overrides/$channelId',
      data: {
        'autoPublishOverride': autoPublishOverride,
        'captionOverride': captionOverride,
      },
    );
    return SocialItemOverride.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteOverride(int itemId, int channelId) async {
    await _dio.delete('/owner/items/$itemId/social/overrides/$channelId');
  }

  // -------- Plan B catalog feed --------

  /// Asks the backend to issue a fresh HMAC-signed feed URL Meta can pull on
  /// a schedule. The returned URL is public — the OWNER copies it into Meta
  /// Commerce Manager. URL expires server-side; re-issue when it does.
  Future<PlanBFeedUrl> issueCatalogFeedUrl() async {
    final r = await _dio.get('/owner/social/feed/url');
    final j = r.data as Map<String, dynamic>;
    return PlanBFeedUrl(
      url: j['url'] as String,
      expiresAt: DateTime.parse(j['expiresAt'] as String),
      ttlSeconds: (j['ttlSeconds'] as num).toInt(),
    );
  }
}

class PlanBFeedUrl {
  final String url;
  final DateTime expiresAt;
  final int ttlSeconds;
  const PlanBFeedUrl({
    required this.url,
    required this.expiresAt,
    required this.ttlSeconds,
  });
}

/// Tuple result of [SocialApi.startOAuth].
class OAuthStart {
  final String authorizationUrl;
  final String stateToken;
  final DateTime expiresAt;
  const OAuthStart({
    required this.authorizationUrl,
    required this.stateToken,
    required this.expiresAt,
  });
}
