import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// A local stand-in for the backend, for the dev flavor and lanes.
///
/// Run `dart run tool/mock_api/server.dart [port]` (default 8080). The
/// Android emulator reaches it at `http://10.0.2.2:8080`.
///
/// Controls for lanes:
/// - `GET /__mock/next?status=503` makes the next API request answer with
///   that status.
/// - `GET /__mock/expire` invalidates the access token, so the next
///   authorized call gets 401 and the app refreshes.
/// - `GET /__mock/revoke` invalidates both tokens, so the refresh fails too.
/// - `GET /__mock/quit` stops the server, for tool/run_patrol.sh.
///
/// Each endpoint is one entry in [routes].
final Map<String, FutureOr<(int, Object?)> Function(HttpRequest request)>
routes = {
  'POST /auth/login': (request) async {
    final body = await _body(request);
    if (body['email'] != demoEmail || body['password'] != demoPassword) {
      return (401, {'error': 'wrong email or password'});
    }
    return (200, _issue());
  },
  'POST /auth/refresh': (request) async {
    final token = (await _body(request))['refreshToken'];
    if (_refresh == null || token != _refresh) {
      return (401, {'error': 'refresh token invalid'});
    }
    return (200, _issue());
  },
  'POST /auth/logout': (request) async {
    if ((await _body(request))['refreshToken'] == _refresh) _revoke();
    return (204, null);
  },
  'GET /me': (request) {
    if (!_authorized(request)) return (401, {'error': 'access token invalid'});
    return (
      200,
      {'id': 'user-1', 'name': 'Mock User', 'email': 'mock.user@example.com'},
    );
  },
  // The demo account comes back on the next sign-in, so lanes can rerun.
  'DELETE /me': (request) {
    if (!_authorized(request)) return (401, {'error': 'access token invalid'});
    _revoke();
    return (204, null);
  },
  'POST /devices': (request) async {
    if (!_authorized(request)) return (401, {'error': 'access token invalid'});
    final token = (await _body(request))['token'];
    if (token is! String || token.isEmpty) return (400, {'error': 'no token'});
    devices.add(token);
    return (204, null);
  },
  'DELETE /devices': (request) async {
    if (!_authorized(request)) return (401, {'error': 'access token invalid'});
    devices.remove((await _body(request))['token']);
    return (204, null);
  },
  // Logs the body, so a lane can read what the app sent.
  'POST /feedback': (request) async {
    if (!_authorized(request)) return (401, {'error': 'access token invalid'});
    final body = await _body(request);
    final rating = body['rating'];
    final message = body['message'];
    if (rating is! int ||
        rating < 1 ||
        rating > 5 ||
        message is! String ||
        message.trim().isEmpty) {
      return (400, {'error': 'needs a rating from 1 to 5 and a message'});
    }
    feedback.add(body);
    stdout.writeln('feedback ${jsonEncode(body)}');
    return (204, null);
  },
};

/// Push tokens registered with `POST /devices`.
final devices = <String>{};

/// Bodies accepted by `POST /feedback`.
final feedback = <Map<String, Object?>>[];

bool _authorized(HttpRequest request) =>
    _access != null &&
    request.headers.value(HttpHeaders.authorizationHeader) == 'Bearer $_access';

const demoEmail = 'demo@corestone.dev';
const demoPassword = 'demo-password';

String? _access;
String? _refresh;
final _random = Random.secure();

Map<String, String> _issue() {
  String token(String kind) {
    final hex = List.generate(16, (_) => _random.nextInt(16).toRadixString(16));
    return 'mock-$kind-${hex.join()}';
  }

  _access = token('access');
  _refresh = token('refresh');
  return {'accessToken': _access!, 'refreshToken': _refresh!};
}

void _revoke() => _access = _refresh = null;

Future<Map<String, Object?>> _body(HttpRequest request) async {
  final decoded = jsonDecode(await utf8.decodeStream(request));
  return decoded is Map<String, Object?> ? decoded : const {};
}

Future<HttpServer> startMockServer({int port = 8080}) async {
  _revoke();
  devices.clear();
  feedback.clear();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  int? nextStatus;
  server.listen((request) async {
    final response = request.response;
    final uri = request.uri;
    if (uri.path == '/__mock/next') {
      nextStatus = int.tryParse(uri.queryParameters['status'] ?? '');
      response.statusCode = nextStatus == null ? 400 : 204;
    } else if (uri.path == '/__mock/expire') {
      _access = null;
      response.statusCode = 204;
    } else if (uri.path == '/__mock/revoke') {
      _revoke();
      response.statusCode = 204;
    } else if (uri.path == '/__mock/quit') {
      response.statusCode = 204;
      await response.close();
      await server.close(force: true);
      return;
    } else if (nextStatus case final status?) {
      nextStatus = null;
      _json(response, status, {'error': 'forced $status'});
    } else if (routes['${request.method} ${uri.path}'] case final route?) {
      try {
        final (status, body) = await route(request);
        _json(response, status, body);
      } on FormatException {
        _json(response, 400, {'error': 'body is not JSON'});
      }
    } else {
      _json(response, 404, {'error': 'no route'});
    }
    stdout.writeln('${request.method} ${uri.path} ${response.statusCode}');
    await response.close();
  });
  return server;
}

void _json(HttpResponse response, int status, Object? body) {
  response.statusCode = status;
  // 204 and 304 must not carry a body, or a kept-alive connection desyncs.
  if (status == 204 || status == 304) return;
  response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
}

Future<void> main(List<String> args) async {
  final server = await startMockServer(
    port: args.isEmpty ? 8080 : int.parse(args.first),
  );
  stdout.writeln('Mock API listening on http://localhost:${server.port}');
}
