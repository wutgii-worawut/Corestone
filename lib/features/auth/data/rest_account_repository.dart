import 'package:corestone/core/network/api_client.dart';
import 'package:corestone/core/typedef.dart';
import 'package:corestone/features/auth/domain/account_repository.dart';

class RestAccountRepository implements AccountRepository {
  /// [api] must carry the auth interceptor.
  const RestAccountRepository(this._api);

  final ApiClient _api;

  @override
  ResultVoid deleteAccount() => _api.delete('/me', parse: (_) {});
}
