import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const testTokens = AuthTokens(accessToken: 'a', refreshToken: 'r');
const testPin = '135790';

/// Registers the app on empty storage for the stage flavor and restores the
/// session and lock, as bootstrap does. A signed-in user has [testPin] set
/// and entered unless [hasPin] or [unlocked] say otherwise. Pair with
/// `tearDown(sl.reset)`.
Future<void> configureTestApp({
  bool signedIn = true,
  bool demoMode = false,
  bool hasPin = true,
  bool unlocked = true,
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
    // One iteration on the test isolate keeps tests fast and lets fake
    // async run the hash; the stored format is the same.
    pins: PinRepository(SecureStore(), iterations: 1, derive: derivePinHash),
  );
  if (signedIn) await sl<TokenStore>().write(testTokens);
  if (signedIn && hasPin) await sl<PinRepository>().setPin(testPin);
  await sl<SessionCubit>().restore();
  await sl<AppLockCubit>().load();
  if (signedIn && hasPin && unlocked) await sl<AppLockCubit>().unlock(testPin);
}
