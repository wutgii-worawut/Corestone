import 'dart:async';

import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/push/push_service.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../network/fake_adapter.dart';

class FakeMessaging implements PushMessaging {
  bool configured = true;
  bool granted = true;
  String token = 'token-1';
  int permissionAsks = 0;
  final refresh = StreamController<String>.broadcast();

  @override
  Future<bool> initialize({required PushTap onTap}) async => configured;

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return granted;
  }

  @override
  Future<bool> hasPermission() async => granted && permissionAsks > 0;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
}

void main() {
  const config = AppConfig(
    flavor: AppFlavor.dev,
    apiBaseUrl: 'http://api.test',
    certPins: [],
  );
  late FakeMessaging messaging;
  late SessionCubit session;
  late PushService push;
  late List<String> calls;
  var deleteStatus = 204;

  ApiClient api() => ApiClient(
    config,
    adapter: FakeAdapter((options) {
      calls.add(
        '${options.method} ${options.path} ${options.data} '
        '${options.headers['Authorization']}',
      );
      final status = options.method == 'DELETE' ? deleteStatus : 204;
      return ResponseBody.fromString('', status);
    }),
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    calls = [];
    deleteStatus = 204;
    messaging = FakeMessaging();
    final client = api();
    session = SessionCubit(
      FakeAuthRepository(),
      TokenStore(SecureStore()),
      onSignOut: (tokens) => push.unregister(tokens),
    );
    push = PushService(
      messaging: messaging,
      api: client,
      plainApi: client,
      flavor: 'dev',
      onTap: (_) {},
    );
    await session.restore();
  });

  tearDown(() async {
    await push.close();
    await session.close();
  });

  Future<void> signIn() =>
      session.signIn(email: 'a@b.c', password: 'pw').then((_) => pumpEvents());

  test('stays off and asks nothing when the flavor has no config', () async {
    messaging.configured = false;
    await push.start(session);
    await signIn();
    expect(push.state, isA<PushOff>());
    expect((push.state as PushOff).reason, 'no Firebase config for dev');
    expect(messaging.permissionAsks, 0);
    expect(calls, isEmpty);
  });

  test('asks permission only after sign in, then registers', () async {
    await push.start(session);
    expect(messaging.permissionAsks, 0);
    await signIn();
    expect(messaging.permissionAsks, 1);
    expect(calls, [startsWith('POST /devices {token: token-1')]);
    expect(push.state, isA<PushReady>());
  });

  test('a denied permission registers nothing', () async {
    messaging.granted = false;
    await push.start(session);
    await signIn();
    expect(push.state, isA<PushPermissionDenied>());
    expect(calls, isEmpty);
  });

  test('a token refresh registers the new token', () async {
    await push.start(session);
    await signIn();
    messaging.refresh.add('token-2');
    await pumpEvents();
    expect(calls.last, startsWith('POST /devices {token: token-2'));
    expect((push.state as PushReady).token, 'token-2');
  });

  test('sign out deletes the token with the old access token', () async {
    await push.start(session);
    await signIn();
    await session.signOut();
    await pumpEvents();
    expect(
      calls.last,
      matches(RegExp(r'^DELETE /devices \{token: token-1\} Bearer .+')),
    );
    expect(push.state, isA<PushOff>());
  });

  test('sign out still succeeds when DELETE fails', () async {
    deleteStatus = 500;
    await push.start(session);
    await signIn();
    await session.signOut();
    await pumpEvents();
    expect(calls.last, startsWith('DELETE /devices'));
    expect(session.state, isA<SessionUnauthenticated>());
  });

  test('a restored session registers without prompting', () async {
    await signIn();
    messaging.permissionAsks = 1;
    await push.start(session);
    await pumpEvents();
    expect(messaging.permissionAsks, 1);
    expect(push.state, isA<PushReady>());
  });

  test('a restored session never asked stays quiet', () async {
    await signIn();
    await push.start(session);
    await pumpEvents();
    expect(messaging.permissionAsks, 0);
    expect(push.state, isA<PushPermissionDenied>());
  });
}

// Dio answers after a few event-loop turns, not one.
Future<void> pumpEvents() =>
    Future<void>.delayed(const Duration(milliseconds: 20));
