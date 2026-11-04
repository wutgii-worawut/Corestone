import 'dart:async';

import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/lock_screen.dart';
import 'package:corestone/features/app_lock/set_pin_screen.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sits above the router, so no route, dialog or deep link can open over
/// it. While a signed-in user is locked or has no PIN, the app under it is
/// built but not painted, focusable or read by screen readers. Outside
/// `resumed` it also covers the app, to keep content out of the app
/// switcher.
class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _lock = sl<AppLockCubit>();
  final _session = sl<SessionCubit>();
  late final AppLifecycleListener _lifecycle;
  bool _covered = false;
  bool _gated = false;

  @override
  void initState() {
    super.initState();
    // Registered before the router's back button dispatcher, so it sees
    // back presses first.
    WidgetsBinding.instance.addObserver(this);
    _lifecycle = AppLifecycleListener(
      onHide: _lock.appHidden,
      onShow: _lock.appShown,
      onStateChange: (state) =>
          setState(() => _covered = state != AppLifecycleState.resumed),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back on the gate leaves the app instead of popping a hidden route.
  @override
  Future<bool> didPopRoute() async {
    if (!_gated) return false;
    unawaited(SystemNavigator.pop());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final lock = context.watch<AppLockCubit>().state;
    final gate = session is! SessionAuthenticated
        ? null
        : switch (lock) {
            AppLockUnlocked() => null,
            AppLockNoPin() => Scaffold(body: SetPinView(onDone: _lock.setPin)),
            AppLockLocked() || AppLockLockedOut() => LockView(
              state: lock,
              onPin: _lock.unlock,
              onForgotPin: () => unawaited(_session.signOut()),
            ),
          };
    _gated = gate != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: _gated,
          child: TickerMode(
            enabled: !_gated,
            child: ExcludeFocus(excluding: _gated, child: widget.child),
          ),
        ),
        if (gate != null) FocusScope(autofocus: true, child: gate),
        if (_covered && gate == null)
          ColoredBox(color: Theme.of(context).colorScheme.surface),
      ],
    );
  }
}
