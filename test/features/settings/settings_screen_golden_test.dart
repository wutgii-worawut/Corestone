@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/settings/settings_screen.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final prefs = Prefs(SharedPreferencesAsync());

  for (final locale in AppLocalizations.supportedLocales) {
    goldenTest(
      'Settings renders in ${locale.languageCode}',
      fileName: 'settings_${locale.languageCode}_light',
      builder: () => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit(prefs)),
          BlocProvider(create: (_) => LocaleCubit(prefs)..setLocale(locale)),
        ],
        child: Theme(
          data: AppTheme.light,
          child: Localizations(
            locale: locale,
            delegates: AppLocalizations.localizationsDelegates,
            child: const SizedBox(
              width: 400,
              height: 320,
              child: SettingsScreen(),
            ),
          ),
        ),
      ),
    );
  }
}
