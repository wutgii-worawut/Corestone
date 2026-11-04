import 'dart:async';

import 'package:corestone/features/app_lock/biometric_service.dart';
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
  const AppLockLocked(this.failedAttempts, {this.biometric = false});

  final int failedAttempts;

  /// The user turned on biometric unlock and the device still has it.
  final bool biometric;

  int get attemptsLeft => AppLockCubit.maxAttempts - failedAttempts;

  @override
  bool operator ==(Object other) =>
      other is AppLockLocked &&
      other.failedAttempts == failedAttempts &&
      other.biometric == biometric;

  @override
  int get hashCode => Object.hash(failedAttempts, biometric);
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
/// Biometrics, when turned on, are a shortcut past the PIN pad, never a
/// replacement for it.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(
    this._pins,
    this._session,
    this._biometrics, {
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
  final BiometricService _biometrics;
  final DateTime Function() _now;
  final Duration Function() _elapsed;
  late final StreamSubscription<SessionState> _sessionChanges;
  DateTime? _hiddenAt;
  Duration? _hiddenElapsed;

  /// The stored count, kept here so a lock after a wrong PIN in the change
  /// flow shows the right number without a store read.
  int _failed = 0;
  bool _biometric = false;
  bool _prompting = false;

  bool get biometricEnabled => _biometric;

  /// Run after [SessionCubit.restore] and before the first frame. Never
  /// throws, so a broken store cannot stop the app from starting.
  Future<void> load() async {
    if (_session.state is! SessionAuthenticated) return _clear();
    try {
      if (!await _pins.hasPin()) return emit(const AppLockNoPin());
      _failed = await _pins.failedAttempts();
      _biometric = await _pins.biometricEnabled();
    } on Object {
      // A PIN that cannot be read cannot be checked, so sign in again.
      _failed = maxAttempts;
    }
    if (_failed >= maxAttempts) return _lockOut();
    _emitLocked();
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
    if (check.failedAttempts < maxAttempts) _emitLocked();
  }

  /// A match unlocks like the right PIN, and like it resets the failed
  /// attempts: both prove the owner is here. A device that lost its
  /// biometrics turns the shortcut off. Anything else leaves the PIN pad.
  Future<void> unlockWithBiometric(BiometricPrompt prompt) async {
    if (state is! AppLockLocked || !_biometric || _prompting) return;
    _prompting = true;
    final BiometricResult result;
    try {
      result = await _biometrics.authenticate(prompt);
    } finally {
      _prompting = false;
    }
    if (state is! AppLockLocked) return;
    switch (result) {
      case BiometricResult.success:
        await _pins.resetFailedAttempts().catchError((Object _) {});
        if (state is! AppLockLocked) return;
        _failed = 0;
        emit(const AppLockUnlocked());
      case BiometricResult.notEnrolled || BiometricResult.notAvailable:
        await disableBiometric();
        if (state is AppLockLocked) _emitLocked();
      case BiometricResult.cancelled ||
          BiometricResult.lockedOut ||
          BiometricResult.error:
        break;
    }
  }

  Future<bool> biometricAvailable() => _biometrics.isAvailable();

  /// Needs a match first, so a device without the user's biometrics cannot
  /// turn it on. Returns whether biometric unlock is on afterwards.
  Future<bool> enableBiometric(BiometricPrompt prompt) async {
    if (state is! AppLockUnlocked || _prompting) return _biometric;
    _prompting = true;
    final BiometricResult result;
    try {
      result = await _biometrics.authenticate(prompt);
    } finally {
      _prompting = false;
    }
    // A lock or sign-out during the prompt wins.
    if (result != BiometricResult.success || state is! AppLockUnlocked) {
      return _biometric;
    }
    try {
      await _pins.setBiometric(enabled: true);
      _biometric = true;
    } on Object {
      // Stays off, as the store says.
    }
    return _biometric;
  }

  Future<void> disableBiometric() async {
    _biometric = false;
    await _pins.setBiometric(enabled: false).catchError((Object _) {});
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
    if (away >= backgroundTimeout || wall.isNegative) _emitLocked();
  }

  void _emitLocked() => emit(AppLockLocked(_failed, biometric: _biometric));

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
    _biometric = false;
    if (!isClosed) emit(const AppLockNoPin());
  }

  @override
  Future<void> close() async {
    await _sessionChanges.cancel();
    return super.close();
  }
}
