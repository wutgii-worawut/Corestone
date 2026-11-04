import 'dart:async';

import 'package:corestone/core/deep_link/deep_link_routes.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens App Links, Universal Links and notification links only once the
/// user is signed in and past the PIN lock.
///
/// A link that arrives before that is held: through login and PIN setup
/// when signed out, until unlock when locked. Only the newest link is
/// held, it opens once, and a sign-out drops it.
class DeepLinkService {
  DeepLinkService({
    required this._host,
    required this._session,
    required this._lock,
    required this._navigate,
  }) {
    _subscriptions
      ..add(
        _session.stream.listen((state) {
          if (state is SessionUnauthenticated) _held = null;
          _flush();
        }),
      )
      ..add(_lock.stream.listen((_) => _flush()));
  }

  final String _host;
  final StateStreamable<SessionState> _session;
  final StateStreamable<AppLockState> _lock;
  final void Function(DeepLinkTarget target) _navigate;
  final _subscriptions = <StreamSubscription<Object?>>[];
  DeepLinkTarget? _held;

  /// [links] is `AppLinks().uriLinkStream`, which also brings the link that
  /// launched the app.
  void start(Stream<Uri> links) => _subscriptions.add(
    links.listen(
      open,
      onError: (Object e) => debugPrint('deep link: stream error: $e'),
    ),
  );

  /// A link from outside the app. One for another host or scheme is
  /// dropped and leaves any held link alone.
  void open(Uri uri) {
    final target = DeepLinkTarget.parse(uri, host: _host);
    if (target == null) {
      debugPrint('deep link: ignored $uri, not https://$_host');
      return;
    }
    _hold(target);
  }

  /// A tapped notification. Its `link` goes through [open]; a tap without
  /// one, or with one that is not a URI, opens Home.
  void openPush(Map<String, Object?> data) {
    final link = data['link'];
    final uri = link is String ? Uri.tryParse(link) : null;
    if (uri == null) return _hold(const HomeLink());
    open(uri);
  }

  void _hold(DeepLinkTarget target) {
    _held = target;
    _flush();
  }

  void _flush() {
    final target = _held;
    if (target == null ||
        _session.state is! SessionAuthenticated ||
        _lock.state is! AppLockUnlocked) {
      return;
    }
    _held = null;
    _navigate(target);
  }

  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}
