import 'dart:async';

import 'package:corestone/core/typedef.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class SessionState {
  const SessionState();
}

/// Before [SessionCubit.restore] has read the [TokenStore].
final class SessionUnknown extends SessionState {
  const SessionUnknown();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated();
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

/// Tokens stay in [TokenStore]; the state only says whether a session
/// exists, so nothing logs or rebuilds on a token rotation.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth, this._tokens) : super(const SessionUnknown());

  final AuthRepository _auth;
  final TokenStore _tokens;

  /// An unreadable store counts as signed out, so startup never fails here.
  Future<void> restore() async {
    final tokens = await _tokens.read().catchError((Object _) => null);
    emit(
      tokens == null
          ? const SessionUnauthenticated()
          : const SessionAuthenticated(),
    );
  }

  ResultVoid signIn({required String email, required String password}) async {
    final result = await _auth.signIn(email: email, password: password);
    return result.fold((failure) async => Left(failure), (tokens) async {
      await _tokens.write(tokens);
      emit(const SessionAuthenticated());
      return const Right(null);
    });
  }

  /// Clears only the [TokenStore], so theme and language survive. The
  /// server revoke is best effort and never blocks signing out.
  Future<void> signOut() async {
    final tokens = await _tokens.read();
    await _tokens.clear();
    emit(const SessionUnauthenticated());
    if (tokens != null) unawaited(_auth.signOut(tokens.refreshToken));
  }

  /// Called by the auth interceptor after it cleared a session the server
  /// rejected.
  void sessionExpired() => emit(const SessionUnauthenticated());
}
