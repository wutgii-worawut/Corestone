import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/auth_repository.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';
import 'package:dio/dio.dart';

/// Attaches the access token and turns a 401 into one refresh and a retry.
///
/// Queued, so concurrent 401s are handled one at a time: the first refreshes,
/// and the rest see the token already changed and only retry. When the
/// server rejects the refresh, the session is cleared and `onSessionExpired`
/// fires once; later 401s find no session and just fail.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._tokens,
    required this._auth,
    required this._retry,
    required this._onSessionExpired,
  });

  static const _header = 'Authorization';
  static const _attemptKey = 'auth_refresh_attempt';

  /// Counts refresh attempts. A request stamped with an older count was sent
  /// before the last attempt, which already failed if its token is unchanged.
  int _attempt = 0;

  final TokenStore _tokens;
  final AuthRepository _auth;

  /// Must send through a client without this interceptor. The retry then
  /// never re-enters the busy error queue, and a second 401 just fails.
  final Future<Response<dynamic>> Function(RequestOptions) _retry;
  final void Function() _onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Dio only catches synchronous throws, so an async one would hang the
    // queue.
    try {
      final tokens = await _tokens.read();
      if (tokens != null) options.headers[_header] = _bearer(tokens);
      options.extra[_attemptKey] = _attempt;
      handler.next(options);
    } on Object catch (e) {
      handler.reject(DioException(requestOptions: options, error: e));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final sent = options.headers[_header];
    if (err.response?.statusCode != 401 || sent == null) {
      return handler.next(err);
    }
    try {
      final current = await _tokens.read();
      final fresh = switch (current) {
        null => null,
        _ when sent != _bearer(current) => current,
        _ when options.extra[_attemptKey] != _attempt => null,
        _ => await _refresh(current),
      };
      if (fresh == null) return handler.next(err);
      options.headers[_header] = _bearer(fresh);
      handler.resolve(await _retry(options));
    } on DioException catch (e) {
      handler.next(e);
    } on Object catch (e) {
      handler.next(DioException(requestOptions: options, error: e));
    }
  }

  /// The new tokens, or null when the request should fail as it is.
  /// Both outcomes apply only if [current] is still stored, so a sign-out
  /// or a new sign-in during the refresh wins.
  Future<AuthTokens?> _refresh(AuthTokens current) async {
    _attempt++;
    final result = await _auth.refresh(current.refreshToken);
    return result.fold(
      (failure) async {
        // A network or server error keeps the session for the next try.
        if (failure
            case UnauthorizedFailure() || ForbiddenFailure() || ClientFailure()
            when await _tokens.replace(current, null)) {
          _onSessionExpired();
        }
        return null;
      },
      (tokens) async => await _tokens.replace(current, tokens) ? tokens : null,
    );
  }

  static String _bearer(AuthTokens tokens) => 'Bearer ${tokens.accessToken}';
}
