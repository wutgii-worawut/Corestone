import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/features/feedback/data/feedback_repository.dart';
import 'package:corestone/features/feedback/feedback_draft.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records each request with the bytes that went on the wire.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.status);

  final int status;
  final requests = <(RequestOptions, String)>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = await requestStream!.expand((chunk) => chunk).toList();
    requests.add((options, utf8.decode(bytes)));
    return ResponseBody.fromString('', status);
  }

  @override
  void close({bool force = false}) {}
}

const _config = AppConfig(
  flavor: AppFlavor.dev,
  apiBaseUrl: 'https://api.test',
  certPins: [],
);

void main() {
  final draft = FeedbackDraft.tryParse(rating: 4, message: ' แอปดีมาก ')!;

  test('send posts the draft with the app context as UTF-8 JSON', () async {
    final adapter = _RecordingAdapter(204);
    final repository = RestFeedbackRepository(
      ApiClient(_config, adapter: adapter),
    );

    expect(
      await repository.send(draft, locale: 'th'),
      const Right<Failure, void>(null),
    );

    final (options, body) = adapter.requests.single;
    expect('${options.method} ${options.path}', 'POST /feedback');
    expect(jsonDecode(body), {
      'rating': 4,
      'message': 'แอปดีมาก',
      'appVersion': appVersion,
      'platform': Platform.operatingSystem,
      'locale': 'th',
    });
  });

  test('a 500 is a ServerFailure', () async {
    final repository = RestFeedbackRepository(
      ApiClient(_config, adapter: _RecordingAdapter(500)),
    );
    expect(
      await repository.send(draft, locale: 'en'),
      const Left<Failure, void>(ServerFailure(500)),
    );
  });
}
