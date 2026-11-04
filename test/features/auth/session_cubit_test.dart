import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late FakeAuthRepository auth;
  late TokenStore tokens;
  late SessionCubit cubit;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    auth = FakeAuthRepository();
    tokens = TokenStore(SecureStore());
    cubit = SessionCubit(auth, tokens);
  });

  tearDown(() => cubit.close());

  test('starts unknown', () {
    expect(cubit.state, isA<SessionUnknown>());
  });

  test('restores a stored session as authenticated', () async {
    await tokens.write(auth.issue());
    await cubit.restore();
    expect(cubit.state, isA<SessionAuthenticated>());
  });

  test('restores no stored session as unauthenticated', () async {
    await cubit.restore();
    expect(cubit.state, isA<SessionUnauthenticated>());
  });

  test('sign in stores the tokens', () async {
    final result = await cubit.signIn(email: 'a@b.c', password: 'pw');
    expect(result.isRight(), isTrue);
    expect(cubit.state, isA<SessionAuthenticated>());
    expect(await tokens.read(), isNotNull);
  });

  test('sign out clears the tokens and keeps theme and language', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = Prefs(SharedPreferencesAsync());
    await ThemeCubit(prefs).setMode(ThemeMode.dark);
    await LocaleCubit(prefs).setLocale(const Locale('th'));
    await cubit.signIn(email: 'a@b.c', password: 'pw');

    await cubit.signOut();

    expect(cubit.state, isA<SessionUnauthenticated>());
    expect(await tokens.read(), isNull);
    expect(auth.signOutCalls, 1);
    final theme = ThemeCubit(prefs);
    final locale = LocaleCubit(prefs);
    await (theme.load(), locale.load()).wait;
    expect(theme.state, ThemeMode.dark);
    expect(locale.state, const Locale('th'));
  });

  test('an expired session becomes unauthenticated', () async {
    await cubit.signIn(email: 'a@b.c', password: 'pw');
    cubit.sessionExpired();
    expect(cubit.state, isA<SessionUnauthenticated>());
  });
}
