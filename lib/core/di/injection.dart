import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/network/auth_interceptor.dart';
import 'package:corestone/core/router/app_router.dart';
import 'package:corestone/core/router/auth_guard.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/app_lock/biometric_service.dart';
import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/rest_account_repository.dart';
import 'package:corestone/features/auth/data/rest_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/account_repository.dart';
import 'package:corestone/features/auth/domain/auth_repository.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

/// [pins] lets tests swap in a cheaper hash, [biometrics] a fake sensor.
void configureDependencies(
  AppConfig config, {
  PinRepository? pins,
  BiometricService? biometrics,
}) {
  // Auth calls and retries skip the auth interceptor, so a 401 on refresh
  // cannot trigger another refresh.
  final authApi = ApiClient(config);
  final secure = SecureStore();
  final tokens = TokenStore(secure);
  final demo = config.demoMode ? FakeAuthRepository() : null;
  sl
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<SecureStore>(secure)
    ..registerSingleton<TokenStore>(tokens)
    ..registerSingleton<AuthRepository>(demo ?? RestAuthRepository(authApi))
    ..registerSingleton<ApiClient>(
      ApiClient(
        config,
        interceptors: [
          AuthInterceptor(
            tokens: tokens,
            auth: sl(),
            retry: authApi.fetch,
            onSessionExpired: () => sl<SessionCubit>().sessionExpired(),
          ),
        ],
      ),
    )
    ..registerSingleton<AccountRepository>(demo ?? RestAccountRepository(sl()))
    ..registerSingleton<Prefs>(Prefs(SharedPreferencesAsync()))
    ..registerSingleton<ThemeCubit>(
      ThemeCubit(sl()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<LocaleCubit>(
      LocaleCubit(sl()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<SessionCubit>(
      SessionCubit(sl(), sl()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<PinRepository>(pins ?? PinRepository(secure))
    ..registerSingleton<AppLockCubit>(
      AppLockCubit(sl(), sl(), biometrics ?? BiometricService()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<AppRouter>(AppRouter(AuthGuard(sl())));
}
