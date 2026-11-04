import 'dart:convert';
import 'dart:io';

/// A local stand-in for the backend, for the dev flavor and lanes.
///
/// Run `dart run tool/mock_api/server.dart [port]` (default 8080). The
/// Android emulator reaches it at `http://10.0.2.2:8080`.
///
/// `GET /__mock/next?status=503` makes the next API request answer with that
/// status, so a lane can drive each failure.
///
/// Each endpoint is one entry in [routes]. CS-07 adds `POST /auth/login` and
/// `POST /auth/refresh`, CS-11 adds `POST /devices` and `DELETE /devices`,
/// and CS-17 adds `POST /feedback`.
final Map<String, Object? Function(HttpRequest request)> routes = {
  'GET /me': (_) => {
    'id': 'user-1',
    'name': 'Mock User',
    'email': 'mock.user@example.com',
  },
};

Future<HttpServer> startMockServer({int port = 8080}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  int? nextStatus;
  server.listen((request) async {
    final response = request.response;
    final uri = request.uri;
    if (uri.path == '/__mock/next') {
      nextStatus = int.tryParse(uri.queryParameters['status'] ?? '');
      response.statusCode = nextStatus == null ? 400 : 204;
    } else if (nextStatus case final status?) {
      nextStatus = null;
      _json(response, status, {'error': 'forced $status'});
    } else if (routes['${request.method} ${uri.path}'] case final route?) {
      _json(response, 200, route(request));
    } else {
      _json(response, 404, {'error': 'no route'});
    }
    stdout.writeln('${request.method} ${uri.path} ${response.statusCode}');
    await response.close();
  });
  return server;
}

void _json(HttpResponse response, int status, Object? body) => response
  ..statusCode = status
  ..headers.contentType = ContentType.json
  ..write(jsonEncode(body));

Future<void> main(List<String> args) async {
  final server = await startMockServer(
    port: args.isEmpty ? 8080 : int.parse(args.first),
  );
  stdout.writeln('Mock API listening on http://localhost:${server.port}');
}
