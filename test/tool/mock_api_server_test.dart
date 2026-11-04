import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/mock_api/server.dart';

void main() {
  late HttpServer server;
  final client = HttpClient();

  setUp(() async => server = await startMockServer(port: 0));
  tearDown(() => server.close(force: true));

  Future<(int, String)> get(String path) async {
    final request = await client.get('127.0.0.1', server.port, path);
    final response = await request.close();
    return (response.statusCode, await utf8.decodeStream(response));
  }

  test('serves /me', () async {
    final (status, body) = await get('/me');
    expect(status, 200);
    expect(jsonDecode(body), containsPair('name', 'Mock User'));
  });

  test('forces the next status once', () async {
    expect((await get('/__mock/next?status=503')).$1, 204);
    expect((await get('/me')).$1, 503);
    expect((await get('/me')).$1, 200);
  });

  test('a forced bodiless status keeps the connection usable', () async {
    for (final status in [204, 304]) {
      await get('/__mock/next?status=$status');
      expect((await get('/me')).$1, status);
      expect((await get('/me')).$1, 200);
    }
  });

  test('unknown routes are 404', () async {
    expect((await get('/nope')).$1, 404);
  });
}
