import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/pin_pad.dart';
import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';

enum _Step { current, enter, confirm }

/// Asks for a new PIN twice, after the current one when [confirmCurrent] is
/// set, then hands it to [onDone].
class SetPinView extends StatefulWidget {
  const SetPinView({required this.onDone, this.confirmCurrent, super.key});

  final Future<void> Function(String pin) onDone;
  final Future<PinCheck> Function(String pin)? confirmCurrent;

  @override
  State<SetPinView> createState() => _SetPinViewState();
}

class _SetPinViewState extends State<SetPinView> {
  late _Step _step = widget.confirmCurrent == null
      ? _Step.enter
      : _Step.current;
  String _first = '';
  String? _error;

  Future<void> _onPin(String pin) async {
    final l10n = context.l10n;
    switch (_step) {
      case _Step.current:
        final check = await widget.confirmCurrent!(pin);
        if (!mounted) return;
        setState(() {
          _step = check.correct ? _Step.enter : _Step.current;
          _error = check.correct
              ? null
              : l10n.wrongPin(AppLockCubit.maxAttempts - check.failedAttempts);
        });
      case _Step.enter:
        setState(() {
          _first = pin;
          _step = _Step.confirm;
          _error = null;
        });
      case _Step.confirm:
        if (pin == _first) return widget.onDone(pin);
        setState(() {
          _step = _Step.enter;
          _error = l10n.pinMismatch;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PinPad(
      key: ValueKey(_step),
      title: switch (_step) {
        _Step.current => l10n.pinCurrentTitle,
        _Step.enter => l10n.pinCreateTitle,
        _Step.confirm => l10n.pinConfirmTitle,
      },
      message: _error ?? (_step == _Step.enter ? l10n.pinCreateSubtitle : null),
      isError: _error != null,
      onCompleted: _onPin,
    );
  }
}

@RoutePage()
class ChangePinScreen extends StatelessWidget {
  const ChangePinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = sl<AppLockCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.changePin)),
      body: SetPinView(
        confirmCurrent: cubit.confirmCurrentPin,
        onDone: (pin) async {
          final messenger = ScaffoldMessenger.of(context);
          final router = context.router;
          final changed = context.l10n.pinChanged;
          await cubit.setPin(pin);
          await router.maybePop();
          messenger.showSnackBar(SnackBar(content: Text(changed)));
        },
      ),
    );
  }
}
