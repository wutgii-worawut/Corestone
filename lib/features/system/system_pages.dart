import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/router/app_router.gr.dart';
import 'package:corestone/core/typedef.dart';

/// A full-screen page for a failure the calling screen cannot fix.
enum SystemPage { maintenance, secureConnection }

/// Who shows a failed call to the user.
enum FailurePresentation {
  /// The calling screen, next to what failed, as a message or snackbar.
  inline,

  /// The auth interceptor refreshes the token, or the session ends and
  /// login shows (CS-07).
  session,
  maintenancePage(SystemPage.maintenance),
  secureConnectionPage(SystemPage.secureConnection);

  const FailurePresentation([this.page]);

  final SystemPage? page;
}

/// The one routing table. No default case, so a new [Failure] subtype does
/// not compile until it is placed here.
FailurePresentation presentationOf(Failure failure) => switch (failure) {
  // Before ServerFailure, which it extends.
  MaintenanceFailure() => FailurePresentation.maintenancePage,
  PinningFailure() => FailurePresentation.secureConnectionPage,
  UnauthorizedFailure() => FailurePresentation.session,
  NetworkFailure() ||
  ForbiddenFailure() ||
  NotFoundFailure() ||
  ClientFailure() ||
  ServerFailure() ||
  BadResponseFailure() ||
  UnknownFailure() => FailurePresentation.inline,
};

/// Runs an action the user started and shows its [SystemPage] when the
/// result needs one.
typedef Guard = ResultFuture<T> Function<T>(ResultFuture<T> Function() action);

ResultFuture<T> unguarded<T>(ResultFuture<T> Function() action) => action();

class SystemPages {
  SystemPages(this._router);

  final StackRouter _router;

  /// Shared, so failures from concurrent calls open one page.
  Future<bool>? _open;

  /// Retry on the page runs [action] again. Leaving the page returns the
  /// failure, for the caller to show inline.
  ResultFuture<T> guard<T>(ResultFuture<T> Function() action) async {
    while (true) {
      final result = await action();
      final page = result.fold((f) => presentationOf(f).page, (_) => null);
      if (page == null || !await _show(page)) return result;
    }
  }

  Future<bool> _show(SystemPage page) => _open ??= _router
      .push<bool>(SystemRoute(page: page))
      .then((retry) => retry ?? false)
      .whenComplete(() => _open = null);
}
