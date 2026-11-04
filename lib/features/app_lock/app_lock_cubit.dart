import 'dart:async';

import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the signed-in user may see app content. Means nothing while the
/// session is signed out: login needs no PIN.
sealed class AppLockState {
  const AppLockState();
}

/// Signed in without a PIN yet, so the user must set one first.
final class AppLockNoPin extends AppLockState {
  const AppLockNoPin();
}

final class AppLockLocked extends AppLockState {
  const AppLockLocked(this.failedAttempts);

  final int failedAttempts;

  int get attemptsLeft => AppLockCubit.maxAttempts - failedAttempts;

  @override
  bool operator ==(Object other) =>
      other is AppLockLocked && other.failedAttempts == failedAttempts;

  @override
  int get hashCode => failedAttempts.hashCode;
}

final class AppLockUnlocked extends AppLockState {
  const AppLockUnlocked();
}

/// Too many wrong PINs, or a forgotten one. The session is being signed
/// out, which then clears the PIN and moves to [AppLockNoPin].
final class AppLockLockedOut extends AppLockState {
  const AppLockLockedOut();
}

/// Owns the PIN gate. Locks on cold start and after [backgroundTimeout] in
/// the background, and signs out after [maxAttempts] wrong PINs in a row,
/// counted across restarts. Any sign-out, for any reason, clears the PIN.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(
    this._pins,
    this._session, {
    DateTime Function()? now,
    Duration Function()? elapsed,
  }) : _now = now ?? DateTime.now,
       _elapsed = elapsed ?? _monotonicClock(),
       // Fails closed until [load] reads the store.
       super(const AppLockLocked(0)) {
    _sessionChanges = _session.stream.listen((session) async {
      if (session is SessionUnauthenticated) await _clear();
    });
  }

  static Duration Function() _monotonicClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  static const maxAttempts = 5;
  static const backgroundTimeout = Duration(seconds: 30);

  final PinRepository _pins;
  final SessionCubit _session;
  final DateTime Function() _now;
  final Duration Function() _elapsed;
  late final StreamSubscription<SessionState> _sessionChanges;
  DateTime? _hiddenAt;
  Duration? _hiddenElapsed;

  /// The stored count, kept here so a lock after a wrong PIN in the change
  /// flow shows the right number without a store read.
  int _failed = 0;

  /// Run after [SessionCubit.restore] and before the first frame. Never
  /// throws, so a broken store cannot stop the app from starting.
  Future<void> load() async {
    if (_session.state is! SessionAuthenticated) return _clear();
    try {
      if (!await _pins.hasPin()) return emit(const AppLockNoPin());
      _failed = await _pins.failedAttempts();
    } on Object {
      // A PIN that cannot be read cannot be checked, so sign in again.
      _failed = maxAttempts;
    }
    if (_failed >= maxAttempts) return _lockOut();
    emit(AppLockLocked(_failed));
  }

  Future<void> setPin(String pin) async {
    await _pins.setPin(pin);
    _failed = 0;
    // A change of PIN that finishes after a lock must not undo the lock.
    if (state is AppLockNoPin) emit(const AppLockUnlocked());
  }

  Future<void> unlock(String pin) async {
    if (state is! AppLockLocked) return;
    final check = await _check(pin);
    if (state is! AppLockLocked) return;
    if (check.correct) return emit(const AppLockUnlocked());
    if (check.failedAttempts < maxAttempts) emit(AppLockLocked(_failed));
  }

  /// Checks the current PIN before a change. A wrong PIN counts toward
  /// [maxAttempts] like one on the lock screen.
  Future<PinCheck> confirmCurrentPin(String pin) => _check(pin);

  /// Signs out, which clears the PIN, so the user can sign in again.
  Future<void> forgotPin() => _lockOut();

  void appHidden() {
    _hiddenAt ??= _now();
    _hiddenElapsed ??= _elapsed();
  }

  void appShown() {
    final hiddenAt = _hiddenAt;
    final hiddenElapsed = _hiddenElapsed;
    _hiddenAt = null;
    _hiddenElapsed = null;
    if (hiddenAt == null || hiddenElapsed == null) return;
    if (state is! AppLockUnlocked) return;
    final wall = _now().difference(hiddenAt);
    final monotonic = _elapsed() - hiddenElapsed;
    // The wall clock can be set back, and the monotonic clock stops while
    // the device sleeps, so the longer of the two decides. A clock set
    // backwards counts as too long.
    final away = wall > monotonic ? wall : monotonic;
    if (away >= backgroundTimeout || wall.isNegative) {
      emit(AppLockLocked(_failed));
    }
  }

  Future<PinCheck> _check(String pin) async {
    PinCheck check;
    try {
      check = await _pins.verify(pin);
    } on Object {
      check = (correct: false, failedAttempts: maxAttempts);
    }
    _failed = check.failedAttempts;
    if (check.failedAttempts >= maxAttempts) await _lockOut();
    return check;
  }

  Future<void> _lockOut() async {
    emit(const AppLockLockedOut());
    try {
      await _session.signOut();
    } on Object {
      // The store failed, so end the session in memory; restore treats an
      // unreadable store as signed out on the next start too.
      _session.sessionExpired();
    }
  }

  Future<void> _clear() async {
    // A record that could not be deleted still fails closed on load and is
    // replaced by the next PIN.
    await _pins.clear().catchError((Object _) {});
    _failed = 0;
    if (!isClosed) emit(const AppLockNoPin());
  }

  @override
  Future<void> close() async {
    await _sessionChanges.cancel();
    return super.close();
  }
}
