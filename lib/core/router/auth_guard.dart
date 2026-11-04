import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/router/app_router.gr.dart';
import 'package:corestone/features/auth/session_cubit.dart';

/// Sends anyone without a session to login. `App` moves the stack when
/// the session changes later.
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._session);

  final SessionCubit _session;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_session.state is SessionAuthenticated) return resolver.next();
    // Same order as auto_route's own AutoRouteGuard.redirect.
    router.push(const LoginRoute());
    resolver.next(false);
  }
}
