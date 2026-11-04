import 'package:bloc_test/bloc_test.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late Prefs prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = Prefs(SharedPreferencesAsync());
  });

  blocTest<ThemeCubit, ThemeMode>(
    'load falls back to system when nothing is saved',
    build: () => ThemeCubit(prefs),
    act: (cubit) => cubit.load(),
    expect: () => [ThemeMode.system],
  );

  blocTest<ThemeCubit, ThemeMode>(
    'load falls back to system on an unknown saved value',
    setUp: () => prefs.setString(ThemeCubit.key, 'sepia'),
    build: () => ThemeCubit(prefs),
    act: (cubit) => cubit.load(),
    expect: () => [ThemeMode.system],
  );

  for (final mode in ThemeMode.values) {
    test('a new cubit loads the saved ${mode.name} mode', () async {
      await ThemeCubit(prefs).setMode(mode);

      final restarted = ThemeCubit(prefs);
      await restarted.load();

      expect(restarted.state, mode);
    });
  }

  blocTest<ThemeCubit, ThemeMode>(
    'setMode emits the chosen mode',
    build: () => ThemeCubit(prefs),
    act: (cubit) => cubit.setMode(ThemeMode.dark),
    expect: () => [ThemeMode.dark],
  );
}
