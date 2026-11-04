import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/typedef.dart';
import 'package:corestone/features/auth/domain/auth_repository.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';
import 'package:dartz/dartz.dart';

/// An in-memory backend for demos and tests. Any credentials sign in, and
/// only the latest refresh token can refresh.
class FakeAuthRepository implements AuthRepository {
  int _issued = 0;
  String? _validRefresh;

  /// Makes every refresh fail with this, such as [UnauthorizedFailure] for a
  /// revoked session or [NetworkFailure] for no connection.
  Failure? refreshFailure;

  /// When set, each refresh waits for it before answering.
  Future<void>? holdRefresh;

  int refreshCalls = 0;
  int signOutCalls = 0;

  AuthTokens issue() {
    _issued++;
    final tokens = AuthTokens(
      accessToken: 'fake-access-$_issued',
      refreshToken: 'fake-refresh-$_issued',
    );
    _validRefresh = tokens.refreshToken;
    return tokens;
  }

  @override
  ResultFuture<AuthTokens> signIn({
    required String email,
    required String password,
  }) async => Right(issue());

  @override
  ResultFuture<AuthTokens> refresh(String refreshToken) async {
    refreshCalls++;
    await holdRefresh;
    if (refreshFailure case final failure?) return Left(failure);
    if (refreshToken != _validRefresh) return const Left(UnauthorizedFailure());
    return Right(issue());
  }

  @override
  ResultVoid signOut(String refreshToken) async {
    signOutCalls++;
    _validRefresh = null;
    return const Right(null);
  }
}
