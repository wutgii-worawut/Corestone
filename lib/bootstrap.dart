import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:corestone/app.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/deep_link/deep_link_service.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/push/push_service.dart';
import 'package:corestone/core/storage/install_marker.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/widgets.dart';

void bootstrap() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initApp();
    runApp(const App());
    sl<DeepLinkService>().start(AppLinks().uriLinkStream);
    // After the first frame, so a slow Firebase start never delays it.
    unawaited(sl<PushService>().start(sl()));
  }, (error, stack) => debugPrint('Uncaught zone error: $error\n$stack'));
}

/// Everything before the first frame. The Patrol suite runs it too, so it
/// starts the app the way a user does.
Future<void> initApp() async {
  configureDependencies(AppConfig.fromEnvironment());
  await wipeSecretsAfterReinstall(sl(), sl());
  // Load the saved theme, language, session and lock before the first frame.
  await (
    sl<ThemeCubit>().load(),
    sl<LocaleCubit>().load(),
    sl<SessionCubit>().restore(),
  ).wait;
  await sl<AppLockCubit>().load();
}
