import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/deep_link/deep_link_service.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/network/auth_interceptor.dart';
import 'package:corestone/core/network/connectivity_cubit.dart';
import 'package:corestone/core/push/firebase_push_messaging.dart';
import 'package:corestone/core/push/push_service.dart';
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
import 'package:corestone/features/feedback/data/feedback_repository.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

/// [pins] lets tests swap in a cheaper hash, [biometrics] a fake sensor,
/// [messaging] a fake push layer, [connectivity] a fake network state.
void configureDependencies(
  AppConfig config, {
  PinRepository? pins,
  BiometricService? biometrics,
  PushMessaging? messaging,
  Stream<List<ConnectivityResult>>? connectivity,
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
    ..registerSingleton<FeedbackRepository>(
      config.demoMode ? FakeFeedbackRepository() : RestFeedbackRepository(sl()),
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
      SessionCubit(
        sl(),
        sl(),
        onSignOut: (tokens) => sl<PushService>().unregister(tokens),
      ),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<PushService>(
      PushService(
        messaging: messaging ?? FirebasePushMessaging(),
        api: sl(),
        plainApi: authApi,
        flavor: config.flavor.name,
        onTap: (data) => sl<DeepLinkService>().openPush(data),
      ),
      dispose: (service) => service.close(),
    )
    ..registerSingleton<PinRepository>(pins ?? PinRepository(secure))
    ..registerSingleton<AppLockCubit>(
      AppLockCubit(sl(), sl(), biometrics ?? BiometricService()),
      dispose: (cubit) => cubit.close(),
    )
    ..registerSingleton<AppRouter>(AppRouter(AuthGuard(sl())))
    ..registerSingleton<SystemPages>(SystemPages(sl<AppRouter>()))
    ..registerSingleton<DeepLinkService>(
      DeepLinkService(
        host: config.deepLinkHost,
        session: sl<SessionCubit>(),
        lock: sl<AppLockCubit>(),
        navigate: (target) => unawaited(target.openIn(sl<AppRouter>())),
      ),
      dispose: (service) => service.close(),
    )
    ..registerSingleton<ConnectivityCubit>(
      ConnectivityCubit(connectivity ?? connectivityChanges(Connectivity())),
      dispose: (cubit) => cubit.close(),
    );
}
