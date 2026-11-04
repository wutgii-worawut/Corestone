import 'package:corestone/core/typedef.dart';

/// Calls about the signed-in user, sent with the session's access token.
abstract interface class AccountRepository {
  /// Deletes the user on the server. Both app stores require in-app
  /// deletion.
  ResultVoid deleteAccount();
}
