import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/errors/failure_message.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/router/app_router.gr.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/features/settings/change_language_screen.dart';
import 'package:corestone/features/settings/change_theme_screen.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.theme),
            subtitle: Text(
              themeModeLabel(l10n, context.watch<ThemeCubit>().state),
            ),
            onTap: () =>
                unawaited(context.router.push(const ChangeThemeRoute())),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              languageLabel(l10n, context.watch<LocaleCubit>().state),
            ),
            onTap: () =>
                unawaited(context.router.push(const ChangeLanguageRoute())),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(l10n.changePin),
            onTap: () => unawaited(context.router.push(const ChangePinRoute())),
          ),
          const _BiometricTile(),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text(l10n.sendFeedback),
            onTap: () => unawaited(context.router.push(const FeedbackRoute())),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: () => unawaited(_confirmSignOut(context)),
          ),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined),
            title: Text(l10n.deleteAccount),
            onTap: () =>
                unawaited(context.router.push(const DeleteAccountRoute())),
          ),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Throw test error'),
              // Async so it reaches the bootstrap zone handler.
              onTap: () => unawaited(
                Future<void>.error(StateError('Test error from Settings')),
              ),
            ),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Call /me'),
              onTap: () => unawaited(_callMe(context)),
            ),
        ],
      ),
    );
  }
}

/// Settings is only reachable unlocked, so a PIN exists. Hidden on a device
/// without enrolled biometrics.
class _BiometricTile extends StatefulWidget {
  const _BiometricTile();

  @override
  State<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends State<_BiometricTile> {
  late final _lock = context.read<AppLockCubit>();
  late final Future<bool> _available = _lock.biometricAvailable();
  bool _busy = false;

  Future<void> _toggle(bool enable) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    if (enable) {
      await _lock.enableBiometric((
        reason: l10n.biometricReason,
        cancel: l10n.cancel,
      ));
    } else {
      await _lock.disableBiometric();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _available,
    builder: (context, available) => available.data ?? false
        ? SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: Text(context.l10n.biometricUnlock),
            value: _lock.biometricEnabled,
            onChanged: _busy ? null : (value) => unawaited(_toggle(value)),
          )
        : const SizedBox.shrink(),
  );
}

Future<void> _confirmSignOut(BuildContext context) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.signOutConfirmTitle),
      content: Text(l10n.signOutConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.signOut),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await sl<SessionCubit>().signOut();
}

Future<void> _callMe(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final result = await sl<SystemPages>().guard(
    () => sl<ApiClient>().get(
      '/me',
      parse: (json) => (json! as Map<String, Object?>)['name']! as String,
    ),
  );
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.fold((f) => failureMessage(l10n, f), (name) => 'OK $name'),
      ),
    ),
  );
}
