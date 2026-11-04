import 'dart:io';

import 'package:corestone/app.dart';
import 'package:corestone/bootstrap.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/deep_link/deep_link_service.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

// Each test starts on a freshly cleared app (clearPackageData in
// android/app/build.gradle.kts) against tool/mock_api/server.dart, on a
// device whose language is English.
const _email = 'demo@corestone.dev';
const _password = 'demo-password';
const _pin = '135790';
const _wrongPin = '000000';

final en = lookupAppLocalizations(const Locale('en'));
final th = lookupAppLocalizations(const Locale('th'));

void main() {
  patrolTest('sign in, set a PIN, land on Home', ($) async {
    await _signInWithPin($);
  });

  patrolTest('locks after 30 s in the background, unlocks with the PIN', (
    $,
  ) async {
    await _signInWithPin($);
    await _lockByBackgrounding($);
    await _enterPin($, _pin);
    await $(_homeTitle).waitUntilVisible();
  });

  patrolTest('five wrong PINs sign out to login', ($) async {
    await _signInWithPin($);
    await _lockByBackgrounding($);
    for (var left = AppLockCubit.maxAttempts - 1; left > 0; left--) {
      await _enterPin($, _wrongPin);
      await $(en.wrongPin(left)).waitUntilVisible();
    }
    await _enterPin($, _wrongPin);
    await $(en.loginTitle).waitUntilVisible();
  });

  patrolTest('switches language to Thai and back, theme to dark', ($) async {
    await _signInWithPin($);
    await _openSettings($);
    await _pickLanguage($, from: en, pick: en.languageThai);
    await $(th.changePin).waitUntilVisible();
    await _pickLanguage($, from: th, pick: th.languageEnglish);
    await $(en.changePin).waitUntilVisible();
    await _pickTheme($, en.themeDark);
    expect(_brightness($), Brightness.dark);
  });

  patrolTest('sends feedback', ($) async {
    await _signInWithPin($);
    await _openSettings($);
    await $(en.sendFeedback).tap();
    await $(find.byTooltip(en.feedbackStars(5, 5))).tap();
    await $(TextField).enterText('Patrol says the template works.');
    await $(en.feedbackSubmit).scrollTo().tap();
    await $(en.feedbackThanksTitle).waitUntilVisible();
  });

  patrolTest('a deep link while locked opens Settings after unlock', (
    $,
  ) async {
    await _signInWithPin($);
    await _lockByBackgrounding($);
    // shortcut: hands the link to the app's handler, skipping the Android
    // intent, since example.com App Links cannot verify on an emulator.
    sl<DeepLinkService>().open(
      Uri.https(sl<AppConfig>().deepLinkHost, '/settings'),
    );
    await $.pumpAndSettle();
    expect($(en.changePin), findsNothing, reason: 'link held behind the lock');
    await _enterPin($, _pin);
    await $(en.changePin).waitUntilVisible();
  });

  patrolTest('sign out returns to login and keeps theme and language', (
    $,
  ) async {
    await _signInWithPin($);
    await _openSettings($);
    await _pickTheme($, en.themeDark);
    await _pickLanguage($, from: en, pick: en.languageThai);
    await $(th.signOut).tap();
    await $(AlertDialog).$(th.signOut).tap();
    await $(th.loginTitle).waitUntilVisible();
    expect(_brightness($), Brightness.dark);
  });
}

String get _homeTitle => 'Corestone ${sl<AppConfig>().flavor.name}';

/// Starts the app as bootstrap does, signs in to the mock API and sets
/// [_pin].
Future<void> _signInWithPin(PatrolIntegrationTester $) async {
  await _expectMockApi();
  await initApp();
  await $.pumpWidgetAndSettle(const App());
  await $(TextField).at(0).enterText(_email);
  await $(TextField).at(1).enterText(_password);
  await $(FilledButton).$(en.signIn).scrollTo().tap();
  await $(en.pinCreateTitle).waitUntilVisible();
  await _enterPin($, _pin);
  await $(en.pinConfirmTitle).waitUntilVisible();
  await _enterPin($, _pin);
  await $(_homeTitle).waitUntilVisible();
}

Future<void> _expectMockApi() async {
  final url = Uri.parse(AppConfig.fromEnvironment().apiBaseUrl);
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    await (await client.getUrl(url.resolve('/__mock/health'))).close();
  } on Object catch (e) {
    fail(
      'Mock API not reachable at $url ($e). Run tool/run_patrol.sh, or '
      'start it with `dart run tool/mock_api/server.dart`.',
    );
  } finally {
    client.close(force: true);
  }
}

/// Real time in the background, past [AppLockCubit.backgroundTimeout].
Future<void> _lockByBackgrounding(PatrolIntegrationTester $) async {
  await $.platform.mobile.pressHome();
  await Future<void>.delayed(
    AppLockCubit.backgroundTimeout + const Duration(seconds: 2),
  );
  await $.platform.mobile.openApp();
  await $(en.lockTitle).waitUntilVisible();
}

Future<void> _enterPin(PatrolIntegrationTester $, String pin) async {
  for (final digit in pin.split('')) {
    await $(TextButton).$(digit).tap();
  }
}

Future<void> _openSettings(PatrolIntegrationTester $) async {
  await $(Icons.settings).tap();
  await $(en.changePin).waitUntilVisible();
}

Future<void> _pickLanguage(
  PatrolIntegrationTester $, {
  required AppLocalizations from,
  required String pick,
}) async {
  await $(from.language).tap();
  await $(RadioListTile<Locale?>).$(pick).tap();
  await $(BackButton).tap();
}

Future<void> _pickTheme(PatrolIntegrationTester $, String pick) async {
  await $(en.theme).tap();
  await $(pick).tap();
  await $(BackButton).tap();
}

Brightness _brightness(PatrolIntegrationTester $) =>
    Theme.of($.tester.element($(Scaffold).first)).brightness;
