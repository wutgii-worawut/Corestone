import 'dart:convert';

import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/error_mapper.dart';
import 'package:corestone/core/network/pinning.dart';
import 'package:corestone/core/typedef.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Turns the decoded response body into a model. A throw becomes
/// [BadResponseFailure].
typedef Parse<T> = T Function(Object? json);

/// The one HTTP client of the app. Every call returns a [Failure] instead of
/// throwing.
class ApiClient {
  ApiClient(
    AppConfig config, {
    HttpClientAdapter? adapter,
    List<Interceptor> interceptors = const [],
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: config.apiBaseUrl,
           connectTimeout: config.apiTimeout,
           receiveTimeout: config.apiTimeout,
           // A redirect could leave https or the pinned host.
           followRedirects: false,
           // Decoded in _send, so a non-JSON error body keeps its status.
           responseType: ResponseType.plain,
         ),
       ) {
    _dio.httpClientAdapter =
        adapter ??
        (config.certPins.isEmpty
            ? IOHttpClientAdapter()
            : IOHttpClientAdapter(
                createHttpClient: () => pinnedHttpClient(config.certPins),
              ));
    _dio.interceptors.addAll(interceptors);
  }

  final Dio _dio;

  ResultFuture<T> get<T>(
    String path, {
    required Parse<T> parse,
    Map<String, Object?>? query,
  }) => _send(() => _dio.get<String>(path, queryParameters: query), parse);

  ResultFuture<T> post<T>(
    String path, {
    required Parse<T> parse,
    Object? data,
  }) => _send(() => _dio.post<String>(path, data: data), parse);

  ResultFuture<T> put<T>(
    String path, {
    required Parse<T> parse,
    Object? data,
  }) => _send(() => _dio.put<String>(path, data: data), parse);

  ResultFuture<T> delete<T>(
    String path, {
    required Parse<T> parse,
    Object? data,
  }) => _send(() => _dio.delete<String>(path, data: data), parse);

  /// Sends prepared [options] as they are and throws [DioException] on
  /// failure. The auth interceptor retries through this on a client without
  /// itself.
  // dynamic, because any other type argument makes Dio rewrite
  // options.responseType and the caller would get a Map, not its String.
  Future<Response<dynamic>> fetch(RequestOptions options) =>
      _dio.fetch<dynamic>(options);

  ResultFuture<T> _send<T>(
    Future<Response<String>> Function() request,
    Parse<T> parse,
  ) async {
    final Response<String> response;
    try {
      response = await request();
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
    try {
      final body = response.data ?? '';
      return Right(parse(body.isEmpty ? null : jsonDecode(body)));
    } on Object {
      return const Left(BadResponseFailure());
    }
  }
}
