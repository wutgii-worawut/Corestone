import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers every request with [respond], or throws what it throws.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  FakeAdapter.json(int status, String body)
    : this(
        (_) => ResponseBody.fromString(
          body,
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

  final ResponseBody Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}
