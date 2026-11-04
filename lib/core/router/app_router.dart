import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/router/app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeShellRoute.page,
      initial: true,
      children: [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: SettingsRoute.page),
      ],
    ),
    AutoRoute(page: ChangeThemeRoute.page),
  ];
}
