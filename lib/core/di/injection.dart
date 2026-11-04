import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/router/app_router.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

void configureDependencies(AppConfig config) {
  sl
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<Prefs>(Prefs(SharedPreferencesAsync()))
    ..registerSingleton<ThemeCubit>(
      ThemeCubit(sl()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<LocaleCubit>(
      LocaleCubit(sl()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<AppRouter>(AppRouter());
}
