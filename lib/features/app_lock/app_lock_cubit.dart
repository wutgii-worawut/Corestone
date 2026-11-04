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

/// Too many wrong PINs. The session is being signed out, which then clears
/// the PIN and moves to [AppLockNoPin].
final class AppLockLockedOut extends AppLockState {
  const AppLockLockedOut();
}

/// Owns the PIN gate. Locks on cold start and after [backgroundTimeout] in
/// the background, and signs out after [maxAttempts] wrong PINs in a row,
/// counted across restarts. Any sign-out, for any reason, clears the PIN.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(this._pins, this._session, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      // Fails closed until [load] reads the store.
      super(const AppLockLocked(0)) {
    _sessionChanges = _session.stream.listen((session) async {
      if (session is SessionUnauthenticated) await _clear();
    });
  }

  static const maxAttempts = 5;
  static const backgroundTimeout = Duration(seconds: 30);

  final PinRepository _pins;
  final SessionCubit _session;
  final DateTime Function() _now;
  late final StreamSubscription<SessionState> _sessionChanges;
  DateTime? _hiddenAt;

  /// The stored count, kept here so a lock after a wrong PIN in the change
  /// flow shows the right number without a store read.
  int _failed = 0;

  /// Run after [SessionCubit.restore] and before the first frame.
  Future<void> load() async {
    if (_session.state is! SessionAuthenticated) return _clear();
    if (!await _pins.hasPin()) return emit(const AppLockNoPin());
    _failed = await _pins.failedAttempts();
    if (_failed >= maxAttempts) return _lockOut();
    emit(AppLockLocked(_failed));
  }

  Future<void> setPin(String pin) async {
    await _pins.setPin(pin);
    _failed = 0;
    emit(const AppLockUnlocked());
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

  void appHidden() => _hiddenAt ??= _now();

  void appShown() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null || state is! AppLockUnlocked) return;
    final away = _now().difference(hiddenAt);
    // A clock set backwards counts as too long, so it cannot skip the lock.
    // shortcut: wall clock, so a clock set back by the time away skips the
    // lock; move to the platform's elapsed-realtime clock if that matters.
    if (away >= backgroundTimeout || away.isNegative) {
      emit(AppLockLocked(_failed));
    }
  }

  Future<PinCheck> _check(String pin) async {
    final check = await _pins.verify(pin);
    _failed = check.failedAttempts;
    if (check.failedAttempts >= maxAttempts) await _lockOut();
    return check;
  }

  Future<void> _lockOut() async {
    emit(const AppLockLockedOut());
    await _session.signOut();
  }

  Future<void> _clear() async {
    await _pins.clear();
    _failed = 0;
    if (!isClosed) emit(const AppLockNoPin());
  }

  @override
  Future<void> close() async {
    await _sessionChanges.cancel();
    return super.close();
  }
}
