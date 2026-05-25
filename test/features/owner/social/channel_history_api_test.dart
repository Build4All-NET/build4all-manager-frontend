import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:build4all_manager/features/owner/social/data/models/social_post.dart';
import 'package:build4all_manager/features/owner/social/data/services/social_api.dart';

void main() {
  late Dio dio;
  late _Stub stub;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    stub = _Stub();
    dio.interceptors.add(stub);
  });

  test('listChannelPosts hits /owner/social/channels/{id}/posts and parses', () async {
    stub.respond('GET', '/owner/social/channels/5/posts', [
      _postJson(id: 100, channelId: 5, channelName: 'Page A', status: 'SUCCEEDED'),
      _postJson(id: 99,  channelId: 5, channelName: 'Page A', status: 'PENDING'),
    ]);
    final api = SocialApi(dio: dio);
    final out = await api.listChannelPosts(5);
    expect(out, hasLength(2));
    expect(out[0].id, 100);
    expect(out[0].status, SocialPostStatus.succeeded);
    expect(out[1].status, SocialPostStatus.pending);
  });

  test('listChannelPosts empty list parses as empty', () async {
    stub.respond('GET', '/owner/social/channels/1/posts', <Map<String, dynamic>>[]);
    final api = SocialApi(dio: dio);
    expect(await api.listChannelPosts(1), isEmpty);
  });

  test('listChannelPosts 403 surfaces as DioException', () async {
    stub.respondError('GET', '/owner/social/channels/1/posts', 403, 'forbidden');
    final api = SocialApi(dio: dio);
    expect(() => api.listChannelPosts(1), throwsA(isA<DioException>()));
  });
}

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

class _Stub extends Interceptor {
  final Map<String, List<_Plan>> _q = {};
  void respond(String method, String path, Object body) {
    (_q['$method $path'] ??= []).add(_Plan(body: body, status: 200));
  }
  void respondError(String method, String path, int status, String msg) {
    (_q['$method $path'] ??= []).add(_Plan(status: status, body: {'message': msg}));
  }
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final queue = _q['${options.method} ${options.path}'];
    if (queue == null || queue.isEmpty) {
      handler.reject(DioException(requestOptions: options,
        error: 'no stub for ${options.path}',
        response: Response(requestOptions: options, statusCode: 599)));
      return;
    }
    final p = queue.removeAt(0);
    final r = Response(requestOptions: options, statusCode: p.status, data: p.body);
    if (p.status >= 400) {
      handler.reject(DioException(requestOptions: options, response: r,
        type: DioExceptionType.badResponse));
    } else {
      handler.resolve(r);
    }
  }
}
class _Plan { final int status; final Object? body; _Plan({this.body, required this.status}); }
