import 'package:corestone/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final flavor in AppFlavor.values) {
    test('parses ${flavor.name}', () {
      final config = AppConfig.parse({
        'APP_FLAVOR': flavor.name,
        'API_BASE_URL': 'https://api-${flavor.name}.example.com',
        'CERT_SHA256': 'abc',
      });

      expect(config.flavor, flavor);
      expect(config.apiBaseUrl, 'https://api-${flavor.name}.example.com');
      expect(config.certSha256, 'abc');
    });
  }

  test('empty API_BASE_URL names the missing key', () {
    expect(
      () => AppConfig.parse({'APP_FLAVOR': 'dev', 'API_BASE_URL': ''}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('API_BASE_URL'),
        ),
      ),
    );
  });

  test('missing APP_FLAVOR names the missing key', () {
    expect(
      () => AppConfig.parse({'API_BASE_URL': 'https://x'}),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('APP_FLAVOR'),
        ),
      ),
    );
  });

  test('unknown APP_FLAVOR is rejected', () {
    expect(
      () => AppConfig.parse({'APP_FLAVOR': 'qa', 'API_BASE_URL': 'https://x'}),
      throwsStateError,
    );
  });

  test('CERT_SHA256 defaults to empty', () {
    final config = AppConfig.parse({
      'APP_FLAVOR': 'prod',
      'API_BASE_URL': 'https://api.example.com',
    });

    expect(config.certSha256, isEmpty);
  });
}
