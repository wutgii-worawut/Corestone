import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/auth_tokens.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

  test('writes, reads back and clears', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = TokenStore(SecureStore());

    expect(await store.read(), isNull);
    await store.write(tokens);
    expect(await store.read(), tokens);
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('an unreadable value counts as signed out', () async {
    for (final raw in ['not json', '{"accessToken":"a"}', '[]']) {
      FlutterSecureStorage.setMockInitialValues({TokenStore.key: raw});
      expect(await TokenStore(SecureStore()).read(), isNull, reason: raw);
    }
  });

  test('toString never shows the tokens', () {
    const secret = AuthTokens(
      accessToken: 'SECRET-A',
      refreshToken: 'SECRET-R',
    );
    expect('$secret', isNot(contains('SECRET')));
  });
}
