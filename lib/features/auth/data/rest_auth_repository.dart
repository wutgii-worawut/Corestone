import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/typedef.dart';
import 'package:corestone/features/auth/domain/auth_repository.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';

class RestAuthRepository implements AuthRepository {
  /// [api] must not carry the auth interceptor, or a 401 on `/auth/refresh`
  /// would try to refresh again.
  const RestAuthRepository(this._api);

  final ApiClient _api;

  @override
  ResultFuture<AuthTokens> signIn({
    required String email,
    required String password,
  }) => _api.post(
    '/auth/login',
    data: {'email': email, 'password': password},
    parse: AuthTokens.fromJson,
  );

  @override
  ResultFuture<AuthTokens> refresh(String refreshToken) => _api.post(
    '/auth/refresh',
    data: {'refreshToken': refreshToken},
    parse: AuthTokens.fromJson,
  );

  @override
  ResultVoid signOut(String refreshToken) => _api.post(
    '/auth/logout',
    data: {'refreshToken': refreshToken},
    parse: (_) {},
  );
}
