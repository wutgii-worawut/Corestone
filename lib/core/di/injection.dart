import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/network/auth_interceptor.dart';
import 'package:corestone/core/router/app_router.dart';
import 'package:corestone/core/router/auth_guard.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/auth/data/rest_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/auth_repository.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

void configureDependencies(AppConfig config) {
  // Auth calls and retries skip the auth interceptor, so a 401 on refresh
  // cannot trigger another refresh.
  final authApi = ApiClient(config);
  final tokens = TokenStore(SecureStore());
  sl
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<TokenStore>(tokens)
    ..registerSingleton<AuthRepository>(RestAuthRepository(authApi))
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
    ..registerSingleton<AppRouter>(AppRouter(AuthGuard(sl())));
}
