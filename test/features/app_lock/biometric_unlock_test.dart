import 'dart:async';

import 'package:corestone/app.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/biometric_service.dart';
import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_biometric_service.dart';
import '../../helpers/test_app.dart';

const pin = '135790';
const wrong = '000000';
const prompt = (reason: 'r', cancel: 'c');

void main() {
  group('AppLockCubit biometrics', () {
    late PinRepository pins;
    late SessionCubit session;
    late FakeBiometricService biometrics;
    late AppLockCubit cubit;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureStore();
      pins = PinRepository(store, iterations: 1);
      session = SessionCubit(FakeAuthRepository(), TokenStore(store));
      await session.signIn(email: 'a@b.c', password: 'pw');
      biometrics = FakeBiometricService();
      cubit = AppLockCubit(pins, session, biometrics);
      await pins.setPin(pin);
      await pins.setBiometric(enabled: true);
      await cubit.load();
    });

    tearDown(() async {
      await cubit.close();
      await session.close();
    });

    test('a locked start offers biometrics when turned on', () {
      expect(cubit.state, const AppLockLocked(0, biometric: true));
    });

    test('a match unlocks and resets the failed attempts', () async {
      await cubit.unlock(wrong);
      await cubit.unlock(wrong);
      expect(cubit.state, const AppLockLocked(2, biometric: true));

      await cubit.unlockWithBiometric(prompt);

      expect(cubit.state, isA<AppLockUnlocked>());
      expect(await pins.failedAttempts(), 0);
    });

    test('cancel leaves the PIN pad, and the PIN still unlocks', () async {
      biometrics.result = BiometricResult.cancelled;
      await cubit.unlockWithBiometric(prompt);
      expect(cubit.state, const AppLockLocked(0, biometric: true));

      await cubit.unlock(pin);
      expect(cubit.state, isA<AppLockUnlocked>());
    });

    test('an OS lockout leaves the PIN pad and the shortcut', () async {
      biometrics.result = BiometricResult.lockedOut;
      await cubit.unlockWithBiometric(prompt);
      expect(cubit.state, const AppLockLocked(0, biometric: true));
    });

    test('no enrolled biometrics turns the shortcut off for good', () async {
      biometrics.result = BiometricResult.notEnrolled;
      await cubit.unlockWithBiometric(prompt);

      expect(cubit.state, const AppLockLocked(0));
      expect(await pins.biometricEnabled(), isFalse);
      await cubit.unlockWithBiometric(prompt);
      expect(biometrics.prompts, 1);
    });

    test('a match that lands after a lockout does not unlock', () async {
      final pending = biometrics.pending = Completer();
      final attempt = cubit.unlockWithBiometric(prompt);
      for (var i = 0; i < AppLockCubit.maxAttempts; i++) {
        await cubit.unlock(wrong);
      }
      pending.complete(BiometricResult.success);
      await attempt;

      expect(cubit.state, isNot(isA<AppLockUnlocked>()));
    });

    test('a match that lands after a sign-out does not unlock', () async {
      final pending = biometrics.pending = Completer();
      final attempt = cubit.unlockWithBiometric(prompt);
      await session.signOut();
      await pumpEventQueue();
      pending.complete(BiometricResult.success);
      await attempt;

      expect(cubit.state, isA<AppLockNoPin>());
    });

    test('sign-out clears the choice with the PIN', () async {
      await session.signOut();
      await pumpEventQueue();
      await session.signIn(email: 'a@b.c', password: 'pw');
      await cubit.setPin(pin);

      expect(cubit.biometricEnabled, isFalse);
      expect(await pins.biometricEnabled(), isFalse);
    });

    test('turning it on needs a match', () async {
      await cubit.disableBiometric();
      await cubit.unlock(pin);

      biometrics.result = BiometricResult.cancelled;
      expect(await cubit.enableBiometric(prompt), isFalse);
      expect(await pins.biometricEnabled(), isFalse);

      biometrics.result = BiometricResult.success;
      expect(await cubit.enableBiometric(prompt), isTrue);
      expect(await pins.biometricEnabled(), isTrue);
    });

    test('changing the PIN keeps the choice', () async {
      await cubit.unlock(pin);
      await cubit.setPin('246802');
      expect(await pins.biometricEnabled(), isTrue);
    });
  });

  group('lock screen', () {
    tearDown(sl.reset);

    const home = 'Corestone stage';

    testWidgets('a cold start prompts once and a match shows Home', (
      tester,
    ) async {
      final biometrics = FakeBiometricService();
      await configureTestApp(
        unlocked: false,
        biometricOn: true,
        biometrics: biometrics,
      );
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(biometrics.prompts, 1);
      expect(find.text(home), findsOneWidget);
    });

    testWidgets('a cancelled prompt leaves a working PIN pad and a retry key', (
      tester,
    ) async {
      final biometrics = FakeBiometricService()
        ..result = BiometricResult.cancelled;
      await configureTestApp(
        unlocked: false,
        biometricOn: true,
        biometrics: biometrics,
      );
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(find.text('Enter your PIN'), findsOneWidget);
      biometrics.result = BiometricResult.success;
      await tester.tap(find.byIcon(Icons.fingerprint));
      await tester.pumpAndSettle();

      expect(biometrics.prompts, 2);
      expect(find.text(home), findsOneWidget);
    });

    testWidgets('PIN still unlocks after a cancelled prompt', (tester) async {
      final biometrics = FakeBiometricService()
        ..result = BiometricResult.cancelled;
      await configureTestApp(
        unlocked: false,
        biometricOn: true,
        biometrics: biometrics,
      );
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      for (final digit in testPin.split('')) {
        await tester.tap(find.widgetWithText(TextButton, digit));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.text(home), findsOneWidget);
    });

    testWidgets('no shortcut and no prompt while biometrics are off', (
      tester,
    ) async {
      final biometrics = FakeBiometricService();
      await configureTestApp(unlocked: false, biometrics: biometrics);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(biometrics.prompts, 0);
      expect(find.byIcon(Icons.fingerprint), findsNothing);
    });
  });

  group('Settings toggle', () {
    tearDown(sl.reset);

    Future<void> openSettings(WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
    }

    testWidgets('hidden on a device without biometrics', (tester) async {
      await configureTestApp(
        biometrics: FakeBiometricService(available: false),
      );
      await openSettings(tester);

      expect(find.text('Unlock with biometrics'), findsNothing);
    });

    testWidgets('turns on after a match', (tester) async {
      final biometrics = FakeBiometricService();
      await configureTestApp(biometrics: biometrics);
      await openSettings(tester);

      final toggle = find.widgetWithText(
        SwitchListTile,
        'Unlock with biometrics',
      );
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(biometrics.prompts, 1);
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(await sl<PinRepository>().biometricEnabled(), isTrue);
    });

    testWidgets('stays off when the prompt is cancelled', (tester) async {
      final biometrics = FakeBiometricService()
        ..result = BiometricResult.cancelled;
      await configureTestApp(biometrics: biometrics);
      await openSettings(tester);

      final toggle = find.widgetWithText(
        SwitchListTile,
        'Unlock with biometrics',
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    });
  });
}
