import 'dart:async';

import 'package:corestone/app.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:flutter/widgets.dart';

void bootstrap() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    configureDependencies(AppConfig.fromEnvironment());
    // Read the saved theme before the first frame so it does not flash.
    await sl<ThemeCubit>().load();
    runApp(const App());
  }, (error, stack) => debugPrint('Uncaught zone error: $error\n$stack'));
}
