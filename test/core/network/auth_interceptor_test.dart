import 'dart:async';
import 'dart:typed_data';

import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/network/auth_interceptor.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = AppConfig(
  flavor: AppFlavor.dev,
  apiBaseUrl: 'https://api.test',
  certPins: [],
);

/// Accepts only [validAccess]. Holds the first [burst] requests until all
/// of them arrived, so they really are concurrent.
class _Server implements HttpClientAdapter {
  _Server({required this.validAccess, this.burst = 1});

  final String validAccess;
  final int burst;
  final seen = <Object?>[];
  final _gate = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final auth = options.headers['Authorization'];
    seen.add(auth);
    if (seen.length == burst) _gate.complete();
    await _gate.future;
    final ok = auth == 'Bearer $validAccess';
    return ResponseBody.fromString(
      ok ? '{"name":"Ada"}' : '{"error":"expired"}',
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeAuthRepository auth;
  late TokenStore tokens;
  var expired = 0;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    auth = FakeAuthRepository();
    tokens = TokenStore(SecureStore());
    expired = 0;
    // Stored fake-access-1; the next refresh issues fake-access-2.
    await tokens.write(auth.issue());
  });

  ApiClient client(_Server server) => ApiClient(
    _config,
    adapter: server,
    interceptors: [
      AuthInterceptor(
        tokens: tokens,
        auth: auth,
        retry: ApiClient(_config, adapter: server).fetch,
        onSessionExpired: () => expired++,
      ),
    ],
  );

  Future<List<Either<Failure, String>>> callMe(ApiClient api, int times) =>
      Future.wait([
        for (var i = 0; i < times; i++)
          api.get('/me', parse: (json) => (json! as Map)['name'] as String),
      ]);

  test('five concurrent 401s share one refresh and all succeed', () async {
    final server = _Server(validAccess: 'fake-access-2', burst: 5);

    final results = await callMe(client(server), 5);

    expect(results, everyElement(const Right<Failure, String>('Ada')));
    expect(server.seen.take(5), everyElement('Bearer fake-access-1'));
    expect(auth.refreshCalls, 1);
    expect((await tokens.read())?.accessToken, 'fake-access-2');
    expect(expired, 0);
  });

  test('a rejected refresh signs out once and fails every call', () async {
    auth.refreshFailure = const UnauthorizedFailure();
    final server = _Server(validAccess: 'fake-access-2', burst: 5);

    final results = await callMe(client(server), 5);

    expect(
      results,
      everyElement(const Left<Failure, String>(UnauthorizedFailure())),
    );
    expect(auth.refreshCalls, 1);
    expect(expired, 1);
    expect(await tokens.read(), isNull);
  });

  test('a 401 after a successful refresh fails without looping', () async {
    final server = _Server(validAccess: 'never');

    final results = await callMe(client(server), 1);

    expect(results.single, const Left<Failure, String>(UnauthorizedFailure()));
    expect(server.seen, ['Bearer fake-access-1', 'Bearer fake-access-2']);
    expect(auth.refreshCalls, 1);
    expect(expired, 0);
  });

  test('a call without a session is sent bare and not refreshed', () async {
    await tokens.clear();
    final server = _Server(validAccess: 'fake-access-1');

    final results = await callMe(client(server), 1);

    expect(results.single, const Left<Failure, String>(UnauthorizedFailure()));
    expect(server.seen, [null]);
    expect(auth.refreshCalls, 0);
  });

  Future<void> untilRefreshStarts() async {
    while (auth.refreshCalls == 0) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('signing out during a refresh stays signed out', () async {
    final hold = Completer<void>();
    auth.holdRefresh = hold.future;
    final call = callMe(client(_Server(validAccess: 'fake-access-2')), 1);
    await untilRefreshStarts();

    await tokens.clear();
    hold.complete();

    expect(
      (await call).single,
      const Left<Failure, String>(UnauthorizedFailure()),
    );
    expect(await tokens.read(), isNull);
    expect(expired, 0);
  });

  test('a late refresh rejection keeps the next user signed in', () async {
    final hold = Completer<void>();
    auth
      ..holdRefresh = hold.future
      ..refreshFailure = const UnauthorizedFailure();
    final call = callMe(client(_Server(validAccess: 'fake-access-2')), 1);
    await untilRefreshStarts();

    const nextUser = AuthTokens(accessToken: 'b', refreshToken: 'rb');
    await tokens.write(nextUser);
    hold.complete();
    await call;

    expect(await tokens.read(), nextUser);
    expect(expired, 0);
  });

  test(
    'a network failure on refresh is tried once and keeps the session',
    () async {
      auth.refreshFailure = const NetworkFailure();
      final server = _Server(validAccess: 'fake-access-2', burst: 5);

      final results = await callMe(client(server), 5);

      expect(
        results,
        everyElement(const Left<Failure, String>(UnauthorizedFailure())),
      );
      expect(auth.refreshCalls, 1);
      expect((await tokens.read())?.accessToken, 'fake-access-1');
      expect(expired, 0);

      auth.refreshFailure = null;
      final later = await callMe(
        client(_Server(validAccess: 'fake-access-2')),
        1,
      );
      expect(later.single, const Right<Failure, String>('Ada'));
    },
  );
}
