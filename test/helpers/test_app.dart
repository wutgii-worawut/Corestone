import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const testTokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

/// Registers the app on empty storage for the stage flavor and restores the
/// session, as bootstrap does. Pair with `tearDown(sl.reset)`.
Future<void> configureTestApp({
  bool signedIn = true,
  bool demoMode = false,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  FlutterSecureStorage.setMockInitialValues({});
  configureDependencies(
    AppConfig(
      flavor: AppFlavor.stage,
      apiBaseUrl: 'https://api-stage.example.com',
      certPins: [],
      demoMode: demoMode,
    ),
  );
  if (signedIn) await sl<TokenStore>().write(testTokens);
  await sl<SessionCubit>().restore();
}
