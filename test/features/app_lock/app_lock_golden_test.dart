@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/lock_screen.dart';
import 'package:corestone/features/app_lock/set_pin_screen.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _frame(Locale locale, Widget child) => Theme(
  data: AppTheme.light,
  child: Localizations(
    locale: locale,
    delegates: AppLocalizations.localizationsDelegates,
    child: SizedBox(width: 400, height: 720, child: child),
  ),
);

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    final code = locale.languageCode;
    goldenTest(
      'Lock screen renders in $code',
      fileName: 'lock_${code}_light',
      builder: () => _frame(
        locale,
        LockView(
          state: const AppLockLocked(2),
          onPin: (_) async {},
          onForgotPin: () {},
          onBiometric: (_) async {},
        ),
      ),
    );
    goldenTest(
      'Lock screen with biometrics renders in $code',
      fileName: 'lock_biometric_${code}_light',
      builder: () => _frame(
        locale,
        LockView(
          state: const AppLockLocked(0, biometric: true),
          onPin: (_) async {},
          onForgotPin: () {},
          onBiometric: (_) async {},
        ),
      ),
    );
    goldenTest(
      'Set PIN renders in $code',
      fileName: 'set_pin_${code}_light',
      builder: () =>
          _frame(locale, Scaffold(body: SetPinView(onDone: (_) async {}))),
    );
  }
}
