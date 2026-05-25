import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4all_manager/features/owner/social/data/models/social_channel.dart';
import 'package:build4all_manager/features/owner/social/data/services/social_api.dart';
import 'package:build4all_manager/features/owner/social/presentation/cubit/social_channels_cubit.dart';
import 'package:build4all_manager/features/owner/social/presentation/cubit/social_channels_state.dart';

/// Cubit-level tests for the channels feature. Stubs Dio at the interceptor
/// layer so the actual HTTP transport is bypassed entirely — fast,
/// deterministic, no I/O.
///
/// The screen-rendering test for the list lives in [_HostScreen] below;
/// it skips the real `OwnerSocialChannelsScreen` so we don't need a
/// MaterialApp ancestor chain (avoids l10n bootstrap in unit-test scope).
void main() {
  late Dio dio;
  late _Stub stub;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    stub = _Stub();
    dio.interceptors.add(stub);
  });

  test('load: parses two channels into typed list', () async {
    stub.respond('GET', '/owner/social/channels', [
      _channelJson(id: 1, name: 'Demo Page'),
      _channelJson(id: 2, name: 'Demo IG', provider: 'INSTAGRAM'),
    ]);

    final cubit = SocialChannelsCubit(api: SocialApi(dio: dio));
    await cubit.load();

    expect(cubit.state.loading, isFalse);
    expect(cubit.state.error, isNull);
    expect(cubit.state.channels, hasLength(2));
    expect(cubit.state.channels[0].provider, SocialChannelProvider.facebookPage);
    expect(cubit.state.channels[1].provider, SocialChannelProvider.instagram);
  });

  test('load: empty list', () async {
    stub.respond('GET', '/owner/social/channels', <Map<String, dynamic>>[]);

    final cubit = SocialChannelsCubit(api: SocialApi(dio: dio));
    await cubit.load();

    expect(cubit.state.channels, isEmpty);
    expect(cubit.state.error, isNull);
  });

  test('load: 403 surfaces as error, no channels leak in', () async {
    stub.respondError('GET', '/owner/social/channels', 403, 'forbidden');

    final cubit = SocialChannelsCubit(api: SocialApi(dio: dio));
    await cubit.load();

    expect(cubit.state.error, isNotNull);
    expect(cubit.state.channels, isEmpty);
  });

  test('setAutoPublish: PATCHes and updates one row in place', () async {
    stub.respond('GET', '/owner/social/channels', [
      _channelJson(id: 7, name: 'Toggle Page', autoPublish: false),
    ]);
    stub.respond('PATCH', '/owner/social/channels/7',
        _channelJson(id: 7, name: 'Toggle Page', autoPublish: true));

    final cubit = SocialChannelsCubit(api: SocialApi(dio: dio));
    await cubit.load();
    expect(cubit.state.channels.single.autoPublishEnabled, isFalse);

    await cubit.setAutoPublish(cubit.state.channels.single, true);

    expect(cubit.state.channels, hasLength(1));
    expect(cubit.state.channels.single.autoPublishEnabled, isTrue);
    expect(stub.requests, contains('PATCH /owner/social/channels/7'));
  });

  test('SocialChannelStatus.userSettable allows only ACTIVE and DISABLED', () {
    expect(SocialChannelStatus.active.userSettable, isTrue);
    expect(SocialChannelStatus.disabled.userSettable, isTrue);
    expect(SocialChannelStatus.tokenExpired.userSettable, isFalse);
    expect(SocialChannelStatus.revoked.userSettable, isFalse);
    expect(SocialChannelStatus.error.userSettable, isFalse);
  });

  test('updateChannel client-side refuses system-managed status', () async {
    final api = SocialApi(dio: dio);
    expect(
      () => api.updateChannel(1, status: SocialChannelStatus.tokenExpired),
      throwsArgumentError,
    );
  });

  testWidgets('renders channel tiles for each row in state', (tester) async {
    stub.respond('GET', '/owner/social/channels', [
      _channelJson(id: 11, name: 'Page A'),
      _channelJson(id: 12, name: 'IG B', provider: 'INSTAGRAM'),
    ]);

    final cubit = SocialChannelsCubit(api: SocialApi(dio: dio));
    await cubit.load();

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(value: cubit, child: const _HostScreen()),
    ));
    await tester.pump();

    expect(find.text('Page A'), findsOneWidget);
    expect(find.text('IG B'),   findsOneWidget);
  });

  testWidgets('empty state renders the placeholder', (tester) async {
    stub.respond('GET', '/owner/social/channels', <Map<String, dynamic>>[]);

    final cubit = SocialChannelsCubit(api: SocialApi(dio: dio));
    await cubit.load();

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider.value(value: cubit, child: const _HostScreen()),
    ));
    await tester.pump();

    expect(find.text('No channels yet'), findsOneWidget);
  });
}

Map<String, dynamic> _channelJson({
  required int id,
  required String name,
  String provider = 'FACEBOOK_PAGE',
  bool autoPublish = false,
}) => {
      'id': id,
      'provider': provider,
      'status': 'ACTIVE',
      'externalAccountId': 'ext-$id',
      'externalAccountName': name,
      'autoPublishEnabled': autoPublish,
      'captionTemplate': null,
      'tokenExpiresAt': null,
      'lastSyncedAt': null,
      'lastError': null,
      'createdAt': '2026-05-25T00:00:00Z',
      'updatedAt': '2026-05-25T00:00:00Z',
      'tokenSuffix': '…abcd',
    };

/// Stub interceptor: resolves known (method, path) tuples with canned bodies.
class _Stub extends Interceptor {
  final Map<String, List<_Plan>> _queues = {};
  final List<String> requests = [];

  void respond(String method, String path, Object body) {
    final key = '$method $path';
    (_queues[key] ??= []).add(_Plan(body: body, status: 200));
  }
  void respondError(String method, String path, int status, String msg) {
    final key = '$method $path';
    (_queues[key] ??= []).add(_Plan(status: status, body: {'message': msg}));
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

/// Minimal renderer that exercises the list-vs-empty branches without
/// dragging the full screen (which would need l10n bootstrap, the router,
/// and Material theming we'd have to mock).
class _HostScreen extends StatelessWidget {
  const _HostScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: BlocBuilder<SocialChannelsCubit, SocialChannelsState>(
          builder: (context, state) {
            if (state.loading) return const Center(child: CircularProgressIndicator());
            if (state.channels.isEmpty) return const Center(child: Text('No channels yet'));
            return ListView(
              children: [
                for (final c in state.channels)
                  ListTile(
                    title: Text(c.externalAccountName ?? c.externalAccountId),
                    subtitle: Text(c.provider.displayName),
                  ),
              ],
            );
          },
        ),
      );
}
