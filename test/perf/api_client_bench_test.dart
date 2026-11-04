@Tags(['perf'])
library;

import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/network/fake_adapter.dart';

const _requests = 1000;
const _config = AppConfig(
  flavor: AppFlavor.dev,
  apiBaseUrl: 'https://api.test',
  certPins: [],
);

Future<int> _timeMicros(Future<void> Function() request) async {
  final watch = Stopwatch()..start();
  await request();
  return watch.elapsedMicroseconds;
}

int _median(List<int> samples) => (samples..sort())[samples.length ~/ 2];

void main() {
  test('ApiClient adds under 1 ms per request over raw Dio', () async {
    final adapter = FakeAdapter.json(200, '{"name":"Ada"}');
    final dio = Dio(BaseOptions(baseUrl: _config.apiBaseUrl))
      ..httpClientAdapter = adapter;
    final client = ApiClient(_config, adapter: adapter);
    var failures = 0;

    Future<void> rawCall() async {
      final data = (await dio.get<Object?>('/me')).data;
      if ((data! as Map<String, Object?>)['name'] != 'Ada') failures++;
    }

    Future<void> apiCall() async {
      final result = await client.get(
        '/me',
        parse: (json) => (json! as Map<String, Object?>)['name']! as String,
      );
      if (result != const Right<Failure, String>('Ada')) failures++;
    }

    final raw = <int>[];
    final api = <int>[];
    // Alternate the sides so warmup and drift favor neither.
    for (var i = 0; i < 200 + _requests; i++) {
      final rawMicros = await _timeMicros(rawCall);
      final apiMicros = await _timeMicros(apiCall);
      if (i >= 200) {
        raw.add(rawMicros);
        api.add(apiMicros);
      }
    }

    // ignore: avoid_print
    print(
      'median per request over $_requests: raw Dio ${_median(raw)} us, '
      'ApiClient ${_median(api)} us',
    );
    expect(failures, 0);
    expect(_median(api) - _median(raw), lessThan(1000));
  });
}
