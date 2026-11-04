import 'dart:io';

import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/network/auth_interceptor.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/auth/data/rest_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/mock_api/server.dart';

void main() {
  late HttpServer server;
  late ApiClient authApi;
  late ApiClient api;
  late TokenStore tokens;
  late RestAuthRepository repository;
  var expired = 0;

  setUp(() async {
    server = await startMockServer(port: 0);
    FlutterSecureStorage.setMockInitialValues({});
    final config = AppConfig(
      flavor: AppFlavor.dev,
      apiBaseUrl: 'http://127.0.0.1:${server.port}',
      certPins: const [],
    );
    authApi = ApiClient(config);
    repository = RestAuthRepository(authApi);
    tokens = TokenStore(SecureStore());
    expired = 0;
    api = ApiClient(
      config,
      interceptors: [
        AuthInterceptor(
          tokens: tokens,
          auth: repository,
          retry: authApi.fetch,
          onSessionExpired: () => expired++,
        ),
      ],
    );
  });

  tearDown(() => server.close(force: true));

  Future<Either<Failure, String>> me() =>
      api.get('/me', parse: (json) => (json! as Map)['name'] as String);

  Future<void> mock(String control) =>
      authApi.get('/__mock/$control', parse: (_) {});

  test('a wrong password is an UnauthorizedFailure', () async {
    final result = await repository.signIn(email: demoEmail, password: 'x');
    expect(result, const Left<Failure, Never>(UnauthorizedFailure()));
  });

  test('an expired access token refreshes and the call succeeds', () async {
    final signedIn = await repository.signIn(
      email: demoEmail,
      password: demoPassword,
    );
    final first = signedIn.getOrElse(() => throw StateError('no tokens'));
    await tokens.write(first);
    expect(await me(), const Right<Failure, String>('Mock User'));

    await mock('expire');

    expect(await me(), const Right<Failure, String>('Mock User'));
    expect((await tokens.read())?.accessToken, isNot(first.accessToken));
    expect(expired, 0);
  });

  test('a revoked session signs out', () async {
    final signedIn = await repository.signIn(
      email: demoEmail,
      password: demoPassword,
    );
    await tokens.write(signedIn.getOrElse(() => throw StateError('no tokens')));

    await mock('revoke');

    expect(await me(), const Left<Failure, String>(UnauthorizedFailure()));
    expect(expired, 1);
    expect(await tokens.read(), isNull);
  });
}
