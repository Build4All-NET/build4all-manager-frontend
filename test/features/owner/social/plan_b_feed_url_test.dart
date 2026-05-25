import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:build4all_manager/features/owner/social/data/models/social_channel.dart';
import 'package:build4all_manager/features/owner/social/data/services/social_api.dart';

void main() {
  late Dio dio;
  late _Stub stub;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    stub = _Stub();
    dio.interceptors.add(stub);
  });

  test('issueCatalogFeedUrl parses url + expiresAt + ttlSeconds', () async {
    stub.respond('GET', '/owner/social/feed/url', {
      'url': 'https://api.example.com/api/social/feed/7.xml?exp=1900000000&sig=abc',
      'expiresAt': '2030-04-09T12:00:00Z',
      'ttlSeconds': 2592000,
    });
    final api = SocialApi(dio: dio);

    final out = await api.issueCatalogFeedUrl();

    expect(out.url, contains('/api/social/feed/7.xml'));
    expect(out.ttlSeconds, 2592000);
    expect(out.expiresAt.year, 2030);
  });

  test('catalog provider detection', () {
    expect(SocialChannelProvider.metaCatalog.isCatalog, isTrue);
    expect(SocialChannelProvider.whatsappCatalog.isCatalog, isTrue);
    expect(SocialChannelProvider.facebookPage.isCatalog, isFalse);
    expect(SocialChannelProvider.instagram.isCatalog, isFalse);
  });

  test('feed URL endpoint 403 surfaces as DioException', () async {
    stub.respondError('GET', '/owner/social/feed/url', 403, 'forbidden');
    final api = SocialApi(dio: dio);
    expect(() => api.issueCatalogFeedUrl(), throwsA(isA<DioException>()));
  });
}

class _Stub extends Interceptor {
  final Map<String, List<_Plan>> _q = {};

  void respond(String method, String path, Object body, {int status = 200}) {
    (_q['$method $path'] ??= []).add(_Plan(body: body, status: status));
  }
  void respondError(String method, String path, int status, String msg) {
    (_q['$method $path'] ??= []).add(_Plan(status: status, body: {'message': msg}));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final key = '${options.method} ${options.path}';
    final queue = _q[key];
    if (queue == null || queue.isEmpty) {
      handler.reject(DioException(
        requestOptions: options,
        error: 'no stub for $key',
        response: Response(requestOptions: options, statusCode: 599)));
      return;
    }
    final p = queue.removeAt(0);
    final r = Response(
        requestOptions: options, statusCode: p.status, data: p.body);
    if (p.status >= 400) {
      handler.reject(DioException(
          requestOptions: options, response: r,
          type: DioExceptionType.badResponse));
    } else {
      handler.resolve(r);
    }
  }
}

class _Plan {
  final int status;
  final Object? body;
  _Plan({this.body, required this.status});
}
