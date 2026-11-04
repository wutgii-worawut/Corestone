enum AppFlavor { dev, stage, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.certSha256,
  });

  factory AppConfig.fromEnvironment() => AppConfig.parse(const {
    'APP_FLAVOR': String.fromEnvironment('APP_FLAVOR'),
    'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
    'CERT_SHA256': String.fromEnvironment('CERT_SHA256'),
  });

  factory AppConfig.parse(Map<String, String> env) {
    final flavorName = _require(env, 'APP_FLAVOR');
    final flavor = AppFlavor.values.asNameMap()[flavorName];
    if (flavor == null) {
      throw StateError(
        'APP_FLAVOR "$flavorName" is not one of '
        '${AppFlavor.values.map((f) => f.name).join(', ')}.',
      );
    }
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: _require(env, 'API_BASE_URL'),
      certSha256: env['CERT_SHA256'] ?? '',
    );
  }

  final AppFlavor flavor;
  final String apiBaseUrl;

  /// Empty means certificate pinning is off.
  final String certSha256;

  static String _require(Map<String, String> env, String key) {
    final value = env[key] ?? '';
    if (value.isEmpty) {
      throw StateError(
        'Missing config key $key. Build with '
        '--dart-define-from-file=config/<flavor>.json.',
      );
    }
    return value;
  }
}
