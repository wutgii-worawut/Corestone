import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/mock_api/server.dart';

void main() {
  late HttpServer server;
  final client = HttpClient();

  setUp(() async => server = await startMockServer(port: 0));
  tearDown(() => server.close(force: true));

  Future<(int, Object?)> send(
    String method,
    String path, {
    Object? body,
    String? bearer,
  }) async {
    final request = await client.open(method, '127.0.0.1', server.port, path);
    if (bearer != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearer');
    }
    if (body != null) request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close();
    final text = await utf8.decodeStream(response);
    return (response.statusCode, text.isEmpty ? null : jsonDecode(text));
  }

  Future<Map<String, Object?>> login() async {
    final (status, body) = await send(
      'POST',
      '/auth/login',
      body: {'email': demoEmail, 'password': demoPassword},
    );
    expect(status, 200);
    return body! as Map<String, Object?>;
  }

  test('the demo user signs in and reads /me', () async {
    final tokens = await login();
    final (status, body) = await send(
      'GET',
      '/me',
      bearer: tokens['accessToken']! as String,
    );
    expect(status, 200);
    expect(body, containsPair('name', 'Mock User'));
  });

  test('a wrong password and a missing token are 401', () async {
    final wrong = await send(
      'POST',
      '/auth/login',
      body: {'email': demoEmail, 'password': 'nope'},
    );
    expect(wrong.$1, 401);
    expect((await send('GET', '/me')).$1, 401);
  });

  test('expire forces a refresh, which rotates both tokens', () async {
    final first = await login();
    await send('GET', '/__mock/expire');
    expect(
      (await send('GET', '/me', bearer: first['accessToken']! as String)).$1,
      401,
    );

    final refresh = {'refreshToken': first['refreshToken']};
    final (status, body) = await send('POST', '/auth/refresh', body: refresh);
    expect(status, 200);
    final second = body! as Map<String, Object?>;
    expect(second['accessToken'], isNot(first['accessToken']));
    expect(
      (await send('GET', '/me', bearer: second['accessToken']! as String)).$1,
      200,
    );
    expect((await send('POST', '/auth/refresh', body: refresh)).$1, 401);
  });

  test('DELETE /me needs the token and ends the session', () async {
    final tokens = await login();
    expect((await send('DELETE', '/me')).$1, 401);
    final access = tokens['accessToken']! as String;
    expect((await send('DELETE', '/me', bearer: access)).$1, 204);
    expect((await send('GET', '/me', bearer: access)).$1, 401);
  });

  test('revoke makes the refresh fail', () async {
    final tokens = await login();
    await send('GET', '/__mock/revoke');
    final refresh = {'refreshToken': tokens['refreshToken']};
    expect((await send('POST', '/auth/refresh', body: refresh)).$1, 401);
  });

  test('forces the next status once', () async {
    expect((await send('GET', '/__mock/next?status=503')).$1, 204);
    expect((await send('GET', '/nope')).$1, 503);
    expect((await send('GET', '/nope')).$1, 404);
  });

  test('a forced bodiless status keeps the connection usable', () async {
    for (final status in [204, 304]) {
      await send('GET', '/__mock/next?status=$status');
      expect((await send('GET', '/nope')).$1, status);
      expect((await send('GET', '/nope')).$1, 404);
    }
  });

  test('feedback needs a session, a rating and a message', () async {
    final access = (await login())['accessToken']! as String;
    const body = {'rating': 4, 'message': 'ดีมาก', 'locale': 'th'};
    expect((await send('POST', '/feedback', body: body)).$1, 401);
    final empty = await send(
      'POST',
      '/feedback',
      body: {'rating': 0, 'message': ' '},
      bearer: access,
    );
    expect(empty.$1, 400);
    final sent = await send('POST', '/feedback', body: body, bearer: access);
    expect(sent.$1, 204);
    expect(feedback, [body]);
  });

  test('devices register and unregister only with a session', () async {
    final access = (await login())['accessToken']! as String;
    expect((await send('POST', '/devices', body: {'token': 't1'})).$1, 401);
    final added = await send(
      'POST',
      '/devices',
      body: {'token': 't1'},
      bearer: access,
    );
    expect(added.$1, 204);
    expect(devices, {'t1'});
    final removed = await send(
      'DELETE',
      '/devices',
      body: {'token': 't1'},
      bearer: access,
    );
    expect(removed.$1, 204);
    expect(devices, isEmpty);
  });

  test('quit answers, then stops listening', () async {
    expect((await send('GET', '/__mock/quit')).$1, 204);
    await expectLater(send('GET', '/me'), throwsA(isA<IOException>()));
  });
}
