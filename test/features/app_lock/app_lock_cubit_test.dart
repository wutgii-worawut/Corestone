import 'dart:async';

import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const pin = '135790';
const wrong = '000000';

void main() {
  late SecureStore store;
  late PinRepository pins;
  late SessionCubit session;
  late AppLockCubit cubit;
  late DateTime now;
  late Duration elapsed;

  AppLockCubit start() =>
      AppLockCubit(pins, session, now: () => now, elapsed: () => elapsed);

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureStore();
    pins = PinRepository(store, iterations: 1);
    session = SessionCubit(FakeAuthRepository(), TokenStore(store));
    await session.signIn(email: 'a@b.c', password: 'pw');
    now = DateTime(2026);
    elapsed = Duration.zero;
    cubit = start();
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
  });

  Future<void> unlocked() async {
    await cubit.load();
    await cubit.setPin(pin);
    expect(cubit.state, isA<AppLockUnlocked>());
  }

  Future<void> lockedWithPin() async {
    await pins.setPin(pin);
    await cubit.load();
  }

  test('fails closed before load', () {
    expect(cubit.state, const AppLockLocked(0));
  });

  test('a signed-in user with no PIN must set one', () async {
    await cubit.load();
    expect(cubit.state, isA<AppLockNoPin>());
    await cubit.setPin(pin);
    expect(cubit.state, isA<AppLockUnlocked>());
  });

  test('a cold start with a PIN is locked until the right PIN', () async {
    await lockedWithPin();
    expect(cubit.state, const AppLockLocked(0));
    await cubit.unlock(wrong);
    expect(cubit.state, const AppLockLocked(1));
    await cubit.unlock(pin);
    expect(cubit.state, isA<AppLockUnlocked>());
  });

  group('background timeout', () {
    test('29 seconds away stays unlocked', () async {
      await unlocked();
      cubit.appHidden();
      now = now.add(const Duration(seconds: 29));
      cubit.appShown();
      expect(cubit.state, isA<AppLockUnlocked>());
    });

    test('30 seconds away locks', () async {
      await unlocked();
      cubit.appHidden();
      now = now.add(const Duration(seconds: 30));
      cubit.appShown();
      expect(cubit.state, const AppLockLocked(0));
    });

    test('times from the first hide, not a later one', () async {
      await unlocked();
      cubit.appHidden();
      now = now.add(const Duration(seconds: 20));
      cubit.appHidden();
      now = now.add(const Duration(seconds: 10));
      cubit.appShown();
      expect(cubit.state, isA<AppLockLocked>());
    });

    test('a clock set backwards locks', () async {
      await unlocked();
      cubit.appHidden();
      now = now.subtract(const Duration(minutes: 5));
      cubit.appShown();
      expect(cubit.state, isA<AppLockLocked>());
    });

    test('a clock set back by exactly the time away still locks', () async {
      await unlocked();
      cubit.appHidden();
      elapsed += const Duration(seconds: 40);
      cubit.appShown();
      expect(cubit.state, isA<AppLockLocked>());
    });

    test('a device that slept through the timeout still locks', () async {
      await unlocked();
      cubit.appHidden();
      now = now.add(const Duration(minutes: 10));
      elapsed += const Duration(seconds: 2);
      cubit.appShown();
      expect(cubit.state, isA<AppLockLocked>());
    });

    test('a right PIN that finishes in the background still locks', () async {
      await lockedWithPin();
      final unlocking = cubit.unlock(pin);
      cubit.appHidden();
      await unlocking;
      now = now.add(const Duration(seconds: 40));
      cubit.appShown();
      expect(cubit.state, isA<AppLockLocked>());
    });
  });

  test('five wrong PINs sign out and clear the PIN', () async {
    await lockedWithPin();
    for (var i = 1; i <= 4; i++) {
      await cubit.unlock(wrong);
      expect(cubit.state, AppLockLocked(i));
    }
    await cubit.unlock(wrong);
    expect(session.state, isA<SessionUnauthenticated>());
    await pumpEventQueue();
    expect(cubit.state, isA<AppLockNoPin>());
    expect(await pins.hasPin(), isFalse);
  });

  test('the wrong-PIN count survives a restart', () async {
    await lockedWithPin();
    for (var i = 0; i < 3; i++) {
      await cubit.unlock(wrong);
    }
    await cubit.close();

    cubit = start();
    await cubit.load();
    expect(cubit.state, const AppLockLocked(3));
    await cubit.unlock(wrong);
    expect(session.state, isA<SessionAuthenticated>());
    await cubit.unlock(wrong);
    expect(session.state, isA<SessionUnauthenticated>());
  });

  test('a restart after the fifth wrong PIN still signs out', () async {
    await pins.setPin(pin);
    for (var i = 0; i < 5; i++) {
      await pins.verify(wrong);
    }
    await cubit.load();
    expect(session.state, isA<SessionUnauthenticated>());
  });

  test(
    'change PIN needs the current one, then only the new one unlocks',
    () async {
      await unlocked();
      expect((await cubit.confirmCurrentPin(wrong)).correct, isFalse);
      expect((await cubit.confirmCurrentPin(pin)).correct, isTrue);
      await cubit.setPin('246810');

      await cubit.close();
      cubit = start();
      await cubit.load();
      await cubit.unlock(pin);
      expect(cubit.state, const AppLockLocked(1));
      await cubit.unlock('246810');
      expect(cubit.state, isA<AppLockUnlocked>());
    },
  );

  test('wrong current PINs in the change flow count toward sign-out', () async {
    await unlocked();
    for (var i = 0; i < 5; i++) {
      await cubit.confirmCurrentPin(wrong);
    }
    expect(session.state, isA<SessionUnauthenticated>());
  });

  test('a lock after a wrong change-flow PIN shows the real count', () async {
    await unlocked();
    await cubit.confirmCurrentPin(wrong);
    cubit.appHidden();
    now = now.add(const Duration(minutes: 1));
    cubit.appShown();
    expect(cubit.state, const AppLockLocked(1));
  });

  test('sign-out clears the PIN', () async {
    await unlocked();
    await session.signOut();
    await pumpEventQueue();
    expect(cubit.state, isA<AppLockNoPin>());
    expect(await pins.hasPin(), isFalse);
  });

  test('a PIN left from a signed-out session is cleared on load', () async {
    await session.signOut();
    await pumpEventQueue();
    await pins.setPin(pin);

    await cubit.close();
    cubit = start();
    await cubit.load();
    expect(cubit.state, isA<AppLockNoPin>());
    expect(await pins.hasPin(), isFalse);
  });

  test('a corrupt PIN record fails closed and signs out', () async {
    await pins.setPin(pin);
    final stored = (await store.read(PinRepository.key))!;
    await store.write(PinRepository.key, stored.substring(3));
    await cubit.load();
    expect(session.state, isA<SessionUnauthenticated>());
    expect(cubit.state, isNot(isA<AppLockUnlocked>()));
  });

  test('an unreadable store does not stop load', () async {
    await cubit.close();
    cubit = AppLockCubit(PinRepository(_BrokenStore()), session);
    await expectLater(cubit.load(), completes);
    expect(session.state, isA<SessionUnauthenticated>());
  });

  test('a PIN change that finishes after a lock keeps the lock', () async {
    final hashing = Completer<void>();
    var holdHash = false;
    pins = PinRepository(
      store,
      iterations: 1,
      derive: (pin, salt, iterations) async {
        if (holdHash) await hashing.future;
        return derivePinHash(pin, salt, iterations);
      },
    );
    await cubit.close();
    cubit = start();
    await unlocked();

    holdHash = true;
    final changing = cubit.setPin('246810');
    cubit.appHidden();
    now = now.add(const Duration(minutes: 1));
    cubit.appShown();
    hashing.complete();
    await changing;
    expect(cubit.state, isA<AppLockLocked>());
  });
}

class _BrokenStore extends SecureStore {
  @override
  Future<String?> read(String key) =>
      Future.error(PlatformException(code: 'decrypt'));

  @override
  Future<void> delete(String key) =>
      Future.error(PlatformException(code: 'decrypt'));
}
