import 'package:equatable/equatable.dart';

/// Every way a call can fail, so callers can switch on it exhaustively.
sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];

  @override
  bool get stringify => true;
}

/// No connection, DNS failure, or a timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// 401. CS-07 refreshes the session or signs out on this.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

/// 403.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure();
}

/// 404.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// Any other 4xx, such as 400, 409, 422 or 429.
final class ClientFailure extends Failure {
  const ClientFailure(this.statusCode);

  final int statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// 5xx. A 503 is the [MaintenanceFailure] subtype.
class ServerFailure extends Failure {
  const ServerFailure(this.statusCode);

  final int statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// 503, which the maintenance screen handles.
final class MaintenanceFailure extends ServerFailure {
  const MaintenanceFailure() : super(503);
}

/// The server answered with a body the caller could not parse.
final class BadResponseFailure extends Failure {
  const BadResponseFailure();
}

/// The server's certificate matched none of the configured pins.
final class PinningFailure extends Failure {
  const PinningFailure();
}

final class UnknownFailure extends Failure {
  const UnknownFailure();
}
