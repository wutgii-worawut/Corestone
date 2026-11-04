import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/l10n/app_localizations.dart';

/// The message a user sees for a failed call. Screens handle the failures
/// that mean something specific to them, such as a 401 on sign-in, first.
String failureMessage(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      NetworkFailure() => l10n.errorOffline,
      ServerFailure() => l10n.errorServer,
      _ => l10n.errorGeneric,
    };
