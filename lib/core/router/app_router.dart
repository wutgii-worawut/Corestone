import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/router/app_router.gr.dart';
import 'package:corestone/core/router/auth_guard.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this._authGuard);

  final AuthGuard _authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeShellRoute.page,
      initial: true,
      guards: [_authGuard],
      children: [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: SettingsRoute.page),
      ],
    ),
    AutoRoute(page: ChangeThemeRoute.page, guards: [_authGuard]),
    AutoRoute(page: ChangeLanguageRoute.page, guards: [_authGuard]),
    AutoRoute(page: DeleteAccountRoute.page, guards: [_authGuard]),
    AutoRoute(page: ChangePinRoute.page, guards: [_authGuard]),
    // No transition, so a sign-out never animates app content out from
    // under the lock.
    CustomRoute<void>(
      page: LoginRoute.page,
      transitionsBuilder: TransitionsBuilders.noTransition,
      duration: Duration.zero,
      reverseDuration: Duration.zero,
    ),
  ];
}
