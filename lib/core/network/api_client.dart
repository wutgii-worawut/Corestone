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
  }) => _send(() => _dio.get<Object?>(path, queryParameters: query), parse);

  ResultFuture<T> post<T>(
    String path, {
    required Parse<T> parse,
    Object? data,
  }) => _send(() => _dio.post<Object?>(path, data: data), parse);

  ResultFuture<T> put<T>(
    String path, {
    required Parse<T> parse,
    Object? data,
  }) => _send(() => _dio.put<Object?>(path, data: data), parse);

  ResultFuture<T> delete<T>(
    String path, {
    required Parse<T> parse,
    Object? data,
  }) => _send(() => _dio.delete<Object?>(path, data: data), parse);

  ResultFuture<T> _send<T>(
    Future<Response<Object?>> Function() request,
    Parse<T> parse,
  ) async {
    final Response<Object?> response;
    try {
      response = await request();
    } on DioException catch (e) {
      return Left(mapDioError(e));
    }
    try {
      return Right(parse(response.data));
    } on Object {
      return const Left(BadResponseFailure());
    }
  }
}
