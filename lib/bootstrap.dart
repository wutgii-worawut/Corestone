import 'dart:async';

import 'package:corestone/app.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:flutter/widgets.dart';

void bootstrap() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      configureDependencies(AppConfig.fromEnvironment());
      runApp(const App());
    },
    (error, stack) => debugPrint('Uncaught zone error: $error\n$stack'),
  );
}
