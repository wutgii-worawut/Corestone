import 'dart:async';

import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PushStatus {
  const PushStatus();
}

/// No token is registered: no Firebase config, signed out, or no token yet.
final class PushOff extends PushStatus {
  const PushOff(this.reason);

  final String reason;
}

final class PushPermissionDenied extends PushStatus {
  const PushPermissionDenied();
}

/// [token] is registered with the server for the signed-in user.
final class PushReady extends PushStatus {
  const PushReady(this.token);

  final String token;
}

/// A tapped notification's data payload.
typedef PushTap = void Function(Map<String, Object?> data);

/// The platform push layer, so tests can run without Firebase.
abstract interface class PushMessaging {
  /// False when the flavor has no Firebase config. [onTap] gets every tapped
  /// notification, including the one that launched the app.
  Future<bool> initialize({required PushTap onTap});

  /// Shows the system prompt the first time, then returns the saved answer.
  Future<bool> requestPermission();

  /// The saved answer, never prompting.
  Future<bool> hasPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;
}

/// Registers this device's push token for the signed-in user.
///
/// Permission is asked on sign in. A session restored at cold start only
/// registers if permission was already granted, so no prompt covers the
/// lock screen. The token
/// is sent with `POST /devices` on sign in and on every refresh, and removed
/// with `DELETE /devices` on sign out.
class PushService extends Cubit<PushStatus> {
  /// [api] carries the auth interceptor. [plainApi] does not, so the sign
  /// out call sends only the old access token it is given.
  PushService({
    required this._messaging,
    required this._api,
    required this._plainApi,
    required this._flavor,
    required this._onTap,
  }) : super(const PushOff('not started'));

  final PushMessaging _messaging;
  final ApiClient _api;
  final ApiClient _plainApi;
  final String _flavor;
  final PushTap _onTap;
  final _subscriptions = <StreamSubscription<Object?>>[];
  SessionCubit? _session;

  /// The last token this device got, kept after sign out for [unregister].
  String? _token;

  Future<void> start(SessionCubit session) async {
    if (!await _messaging.initialize(onTap: _onTap)) {
      debugPrint('push off: no Firebase config for $_flavor');
      emit(PushOff('no Firebase config for $_flavor'));
      return;
    }
    _session = session;
    _subscriptions
      ..add(session.stream.listen(_onSession))
      ..add(_messaging.onTokenRefresh.listen(_onRefresh));
    await _onSession(session.state, prompt: false);
  }

  /// Best effort and never throws, so sign out never waits on it failing.
  Future<void> unregister(AuthTokens tokens) async {
    final token = _token;
    if (token == null) return;
    final result = await _plainApi.delete(
      '/devices',
      data: {'token': token},
      headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
      parse: (_) {},
    );
    result.fold(
      (failure) => debugPrint('push: DELETE /devices failed: $failure'),
      (_) {},
    );
  }

  bool get _signedIn => _session?.state is SessionAuthenticated;

  Future<void> _onSession(SessionState session, {bool prompt = true}) async {
    if (session is! SessionAuthenticated) {
      if (session is SessionUnauthenticated) emit(const PushOff('signed out'));
      return;
    }
    final granted = prompt
        ? await _messaging.requestPermission()
        : await _messaging.hasPermission();
    if (!granted) {
      emit(const PushPermissionDenied());
      return;
    }
    final String? token;
    try {
      token = await _messaging.getToken();
    } on Object catch (e) {
      // iOS has no token until APNs answers; onTokenRefresh brings it.
      debugPrint('push: no token yet: $e');
      return;
    }
    if (token != null) await _register(token);
  }

  Future<void> _onRefresh(String token) async {
    if (state is PushPermissionDenied) return;
    await _register(token);
  }

  Future<void> _register(String token) async {
    _token = token;
    if (!_signedIn) return;
    final result = await _api.post(
      '/devices',
      data: {'token': token, 'platform': defaultTargetPlatform.name},
      parse: (_) {},
    );
    result.fold(
      (failure) => debugPrint('push: POST /devices failed: $failure'),
      (_) {
        if (_signedIn) emit(PushReady(token));
      },
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
