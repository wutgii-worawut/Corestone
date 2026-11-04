import 'dart:io';

import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/error_mapper.dart';
import 'package:corestone/core/network/pinning.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final _options = RequestOptions(path: '/me');

DioException _error(DioExceptionType type, {Object? error}) =>
    DioException(requestOptions: _options, type: type, error: error);

DioException _status(int code) => DioException.badResponse(
  statusCode: code,
  requestOptions: _options,
  response: Response<void>(requestOptions: _options, statusCode: code),
);

void main() {
  final byType = <DioExceptionType, Failure>{
    DioExceptionType.connectionTimeout: const NetworkFailure(),
    DioExceptionType.sendTimeout: const NetworkFailure(),
    DioExceptionType.receiveTimeout: const NetworkFailure(),
    DioExceptionType.transformTimeout: const NetworkFailure(),
    DioExceptionType.connectionError: const NetworkFailure(),
    DioExceptionType.badCertificate: const PinningFailure(),
    DioExceptionType.cancel: const UnknownFailure(),
    DioExceptionType.unknown: const UnknownFailure(),
  };

  test('every DioExceptionType has a case', () {
    expect(
      byType.keys.toSet()..add(DioExceptionType.badResponse),
      DioExceptionType.values.toSet(),
    );
  });

  byType.forEach((type, failure) {
    test('$type maps to $failure', () {
      expect(mapDioError(_error(type)), failure);
    });
  });

  final byStatus = <int, Failure>{
    400: const ClientFailure(400),
    401: const UnauthorizedFailure(),
    403: const ForbiddenFailure(),
    404: const NotFoundFailure(),
    422: const ClientFailure(422),
    429: const ClientFailure(429),
    500: const ServerFailure(500),
    502: const ServerFailure(502),
    503: const MaintenanceFailure(),
    504: const ServerFailure(504),
    302: const BadResponseFailure(),
  };

  byStatus.forEach((code, failure) {
    test('status $code maps to $failure', () {
      expect(mapDioError(_status(code)), failure);
    });
  });

  test('MaintenanceFailure is still a ServerFailure', () {
    expect(mapDioError(_status(503)), isA<ServerFailure>());
  });

  test('unknown errors map by their cause', () {
    Failure cause(Object error) =>
        mapDioError(_error(DioExceptionType.unknown, error: error));

    expect(cause(const PinMismatchException('x')), const PinningFailure());
    expect(cause(const SocketException('down')), const NetworkFailure());
    expect(cause(const FormatException('bad')), const BadResponseFailure());
    expect(cause(StateError('?')), const UnknownFailure());
  });
}
