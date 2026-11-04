import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/pin_pad.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Asks for the PIN over all app content. [state] is [AppLockLocked] or
/// [AppLockLockedOut].
class LockView extends StatelessWidget {
  const LockView({
    required this.state,
    required this.onPin,
    required this.onForgotPin,
    super.key,
  });

  final AppLockState state;
  final Future<void> Function(String pin) onPin;
  final VoidCallback onForgotPin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = this.state;
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
        onCompleted: onPin,
        footer: TextButton(
          onPressed: lockedOut ? null : onForgotPin,
          child: Text(l10n.forgotPin),
        ),
      ),
    );
  }
}
