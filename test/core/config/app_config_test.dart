import 'package:corestone/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final flavor in AppFlavor.values) {
    test('parses ${flavor.name}', () {
      final config = AppConfig.parse({
        'APP_FLAVOR': flavor.name,
        'API_BASE_URL': 'https://api-${flavor.name}.example.com',
        'CERT_SHA256': '',
      });

      expect(config.flavor, flavor);
      expect(config.apiBaseUrl, 'https://api-${flavor.name}.example.com');
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

    expect(config.certPins, isEmpty);
  });

  AppConfig withPins(String raw) => AppConfig.parse({
    'APP_FLAVOR': 'prod',
    'API_BASE_URL': 'https://api.example.com',
    'CERT_SHA256': raw,
  });

  test('CERT_SHA256 holds comma-separated pins, normalized', () {
    final a = 'a' * 64;
    final b = 'B' * 64;
    final bWithColons = [for (var i = 0; i < 64; i += 2) b.substring(i, i + 2)]
        .join(':');

    expect(withPins(' $a , $bWithColons ,').certPins, [a, 'b' * 64]);
  });

  test('a malformed pin names itself', () {
    expect(
      () => withPins('abc'),
      throwsA(
        isA<StateError>().having((e) => e.message, 'message', contains('abc')),
      ),
    );
  });

  test('only dev may use an http API_BASE_URL', () {
    AppConfig parse(String flavor) => AppConfig.parse({
      'APP_FLAVOR': flavor,
      'API_BASE_URL': 'http://10.0.2.2:8080',
    });

    expect(parse('dev').apiBaseUrl, 'http://10.0.2.2:8080');
    expect(() => parse('stage'), throwsStateError);
    expect(() => parse('prod'), throwsStateError);
  });

  test('DEMO_MODE is off by default and only allowed on dev', () {
    AppConfig parse(String flavor, {String demo = 'true'}) => AppConfig.parse({
      'APP_FLAVOR': flavor,
      'API_BASE_URL': 'https://x',
      'DEMO_MODE': demo,
    });
    expect(parse('dev', demo: '').demoMode, isFalse);
    expect(parse('dev').demoMode, isTrue);
    expect(() => parse('stage'), throwsStateError);
    expect(() => parse('prod'), throwsStateError);
  });

  test('DEEP_LINK_HOST is off when empty and must be a bare host', () {
    AppConfig parse(String host) => AppConfig.parse({
      'APP_FLAVOR': 'dev',
      'API_BASE_URL': 'https://x',
      'DEEP_LINK_HOST': host,
    });
    expect(parse('').deepLinkHost, isEmpty);
    const host = 'dev.links.example.com';
    expect(parse(host).deepLinkHost, host);
    expect(() => parse('https://links.example.com'), throwsStateError);
    expect(() => parse('links.example.com/app'), throwsStateError);
    expect(() => parse('Links.Example.com'), throwsStateError);
  });
}
