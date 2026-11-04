import 'package:bloc_test/bloc_test.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:flutter/widgets.dart';
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

  blocTest<LocaleCubit, Locale?>(
    'load follows the system when nothing is saved',
    build: () => LocaleCubit(prefs),
    act: (cubit) => cubit.load(),
    expect: () => [null],
  );

  blocTest<LocaleCubit, Locale?>(
    'load follows the system on an unsupported saved language',
    setUp: () => prefs.setString(LocaleCubit.key, 'xx'),
    build: () => LocaleCubit(prefs),
    act: (cubit) => cubit.load(),
    expect: () => [null],
  );

  for (final locale in const [Locale('en'), Locale('th'), null]) {
    test('a new cubit loads the saved ${locale ?? 'system'} choice', () async {
      await LocaleCubit(prefs).setLocale(const Locale('th'));
      await LocaleCubit(prefs).setLocale(locale);

      final restarted = LocaleCubit(prefs);
      await restarted.load();

      expect(restarted.state, locale);
    });
  }
}
