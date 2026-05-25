import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:build4all_manager/features/owner/social/data/models/social_channel.dart';
import 'package:build4all_manager/features/owner/social/data/services/social_api.dart';
import 'package:build4all_manager/features/owner/social/presentation/cubit/item_social_cubit.dart';

/// Cubit-level coverage for the per-item social panel. Stubs Dio at the
/// interceptor layer; no real HTTP traffic.
void main() {
  late Dio dio;
  late _Stub stub;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    stub = _Stub();
    dio.interceptors.add(stub);
  });

  ItemSocialCubit cubit(int itemId) =>
      ItemSocialCubit(itemId: itemId, api: SocialApi(dio: dio));

  test('load: pulls channels (filters catalogs), overrides, and posts in parallel', () async {
    stub.respond('GET', '/owner/social/channels', [
      _channelJson(id: 1, name: 'Page A'),
      _channelJson(id: 2, name: 'IG', provider: 'INSTAGRAM'),
      _channelJson(id: 3, name: 'Catalog', provider: 'META_CATALOG'),
    ]);
    stub.respond('GET', '/owner/items/42/social/overrides', [
      _overrideJson(channelId: 1, autoPublish: false, caption: 'special'),
    ]);
    stub.respond('GET', '/owner/items/42/social/posts', [
      _postJson(id: 100, channelId: 1, channelName: 'Page A', status: 'SUCCEEDED'),
    ]);

    final c = cubit(42);
    await c.load();

    expect(c.state.loading, isFalse);
    expect(c.state.channels.map((x) => x.id), containsAll([1, 2]));
    expect(c.state.channels.any((x) => x.id == 3),
        isFalse, reason: 'catalog channels filtered out of per-item panel');
    expect(c.state.overridesByChannelId.containsKey(1), isTrue);
    expect(c.state.overridesByChannelId[1]!.captionOverride, 'special');
    expect(c.state.recentPosts, hasLength(1));
    expect(c.state.error, isNull);
  });

  test('effectiveAutoPublish: override null → inherit; explicit wins', () async {
    stub.respond('GET', '/owner/social/channels', [
      _channelJson(id: 1, name: 'P', autoPublish: true),
      _channelJson(id: 2, name: 'Q', autoPublish: false),
    ]);
    stub.respond('GET', '/owner/items/1/social/overrides', [
      _overrideJson(channelId: 2, autoPublish: true),  // force-on
    ]);
    stub.respond('GET', '/owner/items/1/social/posts', <Map<String, dynamic>>[]);

    final c = cubit(1);
    await c.load();

    expect(c.state.effectiveAutoPublish(c.state.channels[0]), isTrue,
        reason: 'inherits channel default true');
    expect(c.state.effectiveAutoPublish(c.state.channels[1]), isTrue,
        reason: 'override true beats channel default false');
  });

  test('setAutoPublishOverride(null) deletes existing override', () async {
    stub.respond('GET', '/owner/social/channels', [
      _channelJson(id: 1, name: 'P', autoPublish: false)]);
    stub.respond('GET', '/owner/items/1/social/overrides',
        [_overrideJson(channelId: 1, autoPublish: false)]);
    stub.respond('GET', '/owner/items/1/social/posts', <Map<String, dynamic>>[]);
    stub.respond('DELETE', '/owner/items/1/social/overrides/1', null, status: 204);

    final c = cubit(1);
    await c.load();
    expect(c.state.overridesByChannelId.containsKey(1), isTrue);

    await c.setAutoPublishOverride(1, null);

    expect(c.state.overridesByChannelId.containsKey(1), isFalse);
    expect(stub.requests, contains('DELETE /owner/items/1/social/overrides/1'));
  });

  test('setAutoPublishOverride(true) upserts and stores the response', () async {
    stub.respond('GET', '/owner/social/channels', [_channelJson(id: 1, name: 'P')]);
    stub.respond('GET', '/owner/items/1/social/overrides', <Map<String, dynamic>>[]);
    stub.respond('GET', '/owner/items/1/social/posts', <Map<String, dynamic>>[]);
    stub.respond('PUT', '/owner/items/1/social/overrides/1',
        _overrideJson(channelId: 1, autoPublish: true));

    final c = cubit(1);
    await c.load();
    await c.setAutoPublishOverride(1, true);

    expect(c.state.overridesByChannelId[1]!.autoPublishOverride, isTrue);
  });

  test('publishNow: prepends the new post to recentPosts and surfaces info message', () async {
    stub.respond('GET', '/owner/social/channels', [_channelJson(id: 1, name: 'P')]);
    stub.respond('GET', '/owner/items/9/social/overrides', <Map<String, dynamic>>[]);
    stub.respond('GET', '/owner/items/9/social/posts', <Map<String, dynamic>>[]);
    stub.respond('POST', '/owner/items/9/social/publish-now',
        _postJson(id: 555, channelId: 1, channelName: 'P', status: 'PENDING'));

    final c = cubit(9);
    await c.load();
    expect(c.state.recentPosts, isEmpty);

    await c.publishNow(1);

    expect(c.state.recentPosts, hasLength(1));
    expect(c.state.recentPosts.first.id, 555);
    expect(c.state.infoMessage, contains('P'));
  });

  test('load: failure surfaces as error and leaves state empty', () async {
    stub.respondError('GET', '/owner/social/channels', 403, 'forbidden');
    final c = cubit(1);
    await c.load();
    expect(c.state.error, isNotNull);
    expect(c.state.channels, isEmpty);
  });
}

Map<String, dynamic> _channelJson({
  required int id,
  required String name,
  String provider = 'FACEBOOK_PAGE',
  bool autoPublish = false,
}) => {
      'id': id, 'provider': provider, 'status': 'ACTIVE',
      'externalAccountId': 'ext-$id', 'externalAccountName': name,
      'autoPublishEnabled': autoPublish,
      'captionTemplate': null,
      'tokenExpiresAt': null, 'lastSyncedAt': null,
      'lastError': null,
      'createdAt': '2026-05-25T00:00:00Z', 'updatedAt': '2026-05-25T00:00:00Z',
      'tokenSuffix': '…abcd',
    };

Map<String, dynamic> _overrideJson({
  required int channelId,
  bool? autoPublish,
  String? caption,
}) => {
      'id': channelId * 100,
      'itemId': 0,
      'channelId': channelId,
      'autoPublishOverride': autoPublish,
      'captionOverride': caption,
      'createdAt': '2026-05-25T00:00:00Z',
      'updatedAt': '2026-05-25T00:00:00Z',
    };

Map<String, dynamic> _postJson({
  required int id,
  required int channelId,
  required String channelName,
  required String status,
}) => {
      'id': id, 'channelId': channelId, 'channelName': channelName,
      'itemId': null,
      'action': 'POST_FEED', 'status': status,
      'attemptCount': status == 'PENDING' ? 0 : 1, 'maxAttempts': 5,
      'nextAttemptAt': null, 'startedAt': null, 'finishedAt': null,
      'externalPostId': status == 'SUCCEEDED' ? 'EXT-$id' : null,
      'externalPermalink': status == 'SUCCEEDED' ? 'https://x/$id' : null,
      'errorCode': null, 'errorMessage': null, 'failureClass': null,
      'createdAt': '2026-05-25T00:00:00Z', 'updatedAt': '2026-05-25T00:00:00Z',
    };

/// Interceptor-based stub identical to the one used in slice-2 tests.
class _Stub extends Interceptor {
  final Map<String, List<_Plan>> _queues = {};
  final List<String> requests = [];

  void respond(String method, String path, Object? body, {int status = 200}) {
    (_queues['$method $path'] ??= []).add(_Plan(body: body, status: status));
  }
  void respondError(String method, String path, int status, String msg) {
    (_queues['$method $path'] ??= []).add(_Plan(status: status, body: {'message': msg}));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = '${options.method} ${options.path}';
    requests.add(key);
    final queue = _queues[key];
    if (queue == null || queue.isEmpty) {
      handler.reject(DioException(
          requestOptions: options,
          error: 'No queued response for $key',
          response: Response(requestOptions: options, statusCode: 599)));
      return;
    }
    final plan = queue.removeAt(0);
    final response = Response(
      requestOptions: options,
      statusCode: plan.status,
      data: plan.body,
    );
    if (plan.status >= 400) {
      handler.reject(DioException(
          requestOptions: options, response: response,
          type: DioExceptionType.badResponse));
    } else {
      handler.resolve(response);
    }
  }
}

class _Plan {
  final int status;
  final Object? body;
  _Plan({this.body, required this.status});
}
