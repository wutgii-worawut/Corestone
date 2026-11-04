import 'package:corestone/core/typedef.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';

abstract interface class AuthRepository {
  ResultFuture<AuthTokens> signIn({
    required String email,
    required String password,
  });

  /// Trades [refreshToken] for a new pair. The old refresh token stops
  /// working.
  ResultFuture<AuthTokens> refresh(String refreshToken);

  /// Revokes [refreshToken] on the server.
  ResultVoid signOut(String refreshToken);
}
