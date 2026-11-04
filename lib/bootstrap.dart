import 'dart:async';

import 'package:corestone/app.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/widgets.dart';

void bootstrap() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    configureDependencies(AppConfig.fromEnvironment());
    // Load the saved theme, language and session before the first frame.
    await (
      sl<ThemeCubit>().load(),
      sl<LocaleCubit>().load(),
      sl<SessionCubit>().restore(),
    ).wait;
    runApp(const App());
  }, (error, stack) => debugPrint('Uncaught zone error: $error\n$stack'));
}
