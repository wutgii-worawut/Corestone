import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_adapter.dart';

const _config = AppConfig(
  flavor: AppFlavor.dev,
  apiBaseUrl: 'https://api.test',
  certPins: [],
);

String _name(Object? json) =>
    (json! as Map<String, Object?>)['name']! as String;

Future<Either<Failure, String>> _me(HttpClientAdapter adapter) =>
    ApiClient(_config, adapter: adapter).get('/me', parse: _name);

void main() {
  test('success parses the body', () async {
    expect(
      await _me(FakeAdapter.json(200, '{"name":"Ada"}')),
      const Right<Failure, String>('Ada'),
    );
  });

  test('timeout is a NetworkFailure', () async {
    final adapter = FakeAdapter(
      (options) => throw DioException.receiveTimeout(
        timeout: _config.apiTimeout,
        requestOptions: options,
      ),
    );
    expect(await _me(adapter), const Left<Failure, String>(NetworkFailure()));
  });

  final byStatus = {
    401: const UnauthorizedFailure(),
    500: const ServerFailure(500),
    503: const MaintenanceFailure(),
  };
  byStatus.forEach((status, failure) {
    test('$status is $failure', () async {
      expect(
        await _me(FakeAdapter.json(status, '{"error":"x"}')),
        Left<Failure, String>(failure),
      );
    });
  });

  test('a non-JSON error body keeps its status', () async {
    expect(
      await _me(FakeAdapter.json(503, '<html>down</html>')),
      const Left<Failure, String>(MaintenanceFailure()),
    );
    expect(
      await _me(FakeAdapter.json(401, 'Unauthorized')),
      const Left<Failure, String>(UnauthorizedFailure()),
    );
  });

  test('a redirect is not followed', () async {
    expect(
      await _me(FakeAdapter.json(302, '')),
      const Left<Failure, String>(BadResponseFailure()),
    );
  });

  test('an empty success body parses as null', () async {
    final client = ApiClient(_config, adapter: FakeAdapter.json(204, ''));
    expect(
      await client.delete('/me', parse: (json) => json),
      const Right<Failure, Object?>(null),
    );
  });

  test('malformed JSON is a BadResponseFailure', () async {
    expect(
      await _me(FakeAdapter.json(200, '{"name":')),
      const Left<Failure, String>(BadResponseFailure()),
    );
  });

  test('a body the parser rejects is a BadResponseFailure', () async {
    expect(
      await _me(FakeAdapter.json(200, '{"id":1}')),
      const Left<Failure, String>(BadResponseFailure()),
    );
  });

  test('uses the base URL and runs added interceptors', () async {
    final seen = <Uri>[];
    final client = ApiClient(
      _config,
      adapter: FakeAdapter.json(200, '{"name":"Ada"}'),
      interceptors: [
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.followRedirects, isFalse);
            seen.add(options.uri);
            handler.next(options);
          },
        ),
      ],
    );
    await client.post('/me', data: {'a': 1}, parse: _name);
    expect(seen, [Uri.parse('https://api.test/me')]);
  });
}
