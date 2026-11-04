import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/biometric_service.dart';
import 'package:corestone/features/app_lock/pin_pad.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Asks for the PIN over all app content. [state] is [AppLockLocked] or
/// [AppLockLockedOut]. With biometrics on, it prompts once when it appears
/// and offers a key to prompt again; the PIN pad works throughout.
class LockView extends StatefulWidget {
  const LockView({
    required this.state,
    required this.onPin,
    required this.onForgotPin,
    required this.onBiometric,
    super.key,
  });

  final AppLockState state;
  final Future<void> Function(String pin) onPin;
  final VoidCallback onForgotPin;
  final Future<void> Function(BiometricPrompt prompt) onBiometric;

  @override
  State<LockView> createState() => _LockViewState();
}

class _LockViewState extends State<LockView> {
  AppLifecycleListener? _waitForResume;

  bool get _biometric => switch (widget.state) {
    AppLockLocked(biometric: true) => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    if (!_biometric) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    // A lock on the way back from the background appears before the app is
    // resumed, and the system prompt cannot show until it is.
    if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
    } else {
      _waitForResume = AppLifecycleListener(
        onResume: () {
          _waitForResume?.dispose();
          _waitForResume = null;
          _prompt();
        },
      );
    }
  }

  @override
  void dispose() {
    _waitForResume?.dispose();
    super.dispose();
  }

  void _prompt() {
    if (!mounted || !_biometric) return;
    final l10n = context.l10n;
    widget.onBiometric((
      reason: l10n.biometricReason,
      cancel: l10n.biometricUsePin,
    )).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = widget.state;
    final lockedOut = state is AppLockLockedOut;
    return Scaffold(
      body: PinPad(
        title: l10n.lockTitle,
        message: switch (state) {
          AppLockLockedOut() => l10n.lockedOut,
          AppLockLocked(failedAttempts: > 0, :final attemptsLeft) =>
            l10n.wrongPin(attemptsLeft),
          _ => null,
        },
        isError:
            lockedOut || state is AppLockLocked && state.failedAttempts > 0,
        enabled: !lockedOut,
        onCompleted: widget.onPin,
        shortcut: _biometric
            ? IconButton(
                onPressed: _prompt,
                iconSize: 32,
                color: Theme.of(context).colorScheme.primary,
                icon: Icon(
                  Icons.fingerprint,
                  semanticLabel: l10n.biometricUnlock,
                ),
              )
            : null,
        footer: TextButton(
          onPressed: lockedOut ? null : widget.onForgotPin,
          child: Text(l10n.forgotPin),
        ),
      ),
    );
  }
}
