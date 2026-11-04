import 'package:equatable/equatable.dart';

/// The pair the backend issues on sign-in and on every refresh.
final class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  /// Throws [FormatException] unless both tokens are non-empty strings.
  factory AuthTokens.fromJson(Object? json) => switch (json) {
    {'accessToken': final String access, 'refreshToken': final String refresh}
        when access.isNotEmpty && refresh.isNotEmpty =>
      AuthTokens(accessToken: access, refreshToken: refresh),
    _ => throw const FormatException('Expected accessToken and refreshToken'),
  };

  final String accessToken;
  final String refreshToken;

  Map<String, String> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };

  @override
  List<Object?> get props => [accessToken, refreshToken];

  /// Never print the tokens, not even in debug logs.
  @override
  bool get stringify => false;
}
