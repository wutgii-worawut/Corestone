import 'dart:convert';

import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';

/// The only place tokens are persisted. Both tokens share one key, so a crash
/// mid-write can never leave a mismatched pair. Operations run one at a
/// time, so [replace] cannot interleave with a sign-out.
class TokenStore {
  TokenStore(this._store);

  static const key = 'auth_tokens';

  final SecureStore _store;
  Future<void> _last = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _last.then((_) => op());
    _last = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Null when signed out or when the stored value is unreadable.
  Future<AuthTokens?> read() => _serial(_read);

  Future<void> write(AuthTokens tokens) => _serial(() => _write(tokens));

  Future<void> clear() => _serial(() => _store.delete(key));

  /// Stores [next], or clears when null, only while [expected] is still the
  /// stored pair. False means the session changed meanwhile.
  Future<bool> replace(AuthTokens expected, AuthTokens? next) =>
      _serial(() async {
        if (await _read() != expected) return false;
        await (next == null ? _store.delete(key) : _write(next));
        return true;
      });

  Future<AuthTokens?> _read() async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      return AuthTokens.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  Future<void> _write(AuthTokens tokens) =>
      _store.write(key, jsonEncode(tokens.toJson()));
}
