import 'dart:io';

import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/network/pinning.dart';
import 'package:dio/dio.dart';

Failure mapDioError(DioException error) => switch (error.type) {
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout ||
  DioExceptionType.connectionError => const NetworkFailure(),
  DioExceptionType.badCertificate => const PinningFailure(),
  DioExceptionType.badResponse => mapStatusCode(error.response?.statusCode),
  // shortcut: nothing cancels requests yet, add a CancelledFailure when
  // something does.
  DioExceptionType.cancel => const UnknownFailure(),
  DioExceptionType.unknown => switch (error.error) {
    PinMismatchException() => const PinningFailure(),
    SocketException() => const NetworkFailure(),
    FormatException() => const BadResponseFailure(),
    _ => const UnknownFailure(),
  },
};

Failure mapStatusCode(int? statusCode) => switch (statusCode) {
  401 => const UnauthorizedFailure(),
  403 => const ForbiddenFailure(),
  404 => const NotFoundFailure(),
  503 => const MaintenanceFailure(),
  final code? when code >= 400 && code < 500 => ClientFailure(code),
  final code? when code >= 500 && code < 600 => ServerFailure(code),
  _ => const BadResponseFailure(),
};
