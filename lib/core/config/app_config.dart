enum AppFlavor { dev, stage, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.certPins,
    this.apiTimeout = const Duration(seconds: 15),
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
    final apiBaseUrl = _require(env, 'API_BASE_URL');
    // dart:io ignores Android's cleartext policy and iOS ATS, so http is
    // blocked here instead. Only dev may use it, for the local mock API.
    if (flavor != AppFlavor.dev && Uri.parse(apiBaseUrl).scheme != 'https') {
      throw StateError('API_BASE_URL must be https for ${flavor.name}.');
    }
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      certPins: _parsePins(env['CERT_SHA256'] ?? ''),
    );
  }

  final AppFlavor flavor;
  final String apiBaseUrl;

  /// Lowercase hex SHA-256 of the leaf certificate's DER bytes, from the
  /// comma-separated `CERT_SHA256` key. Empty means pinning is off. List the
  /// next certificate's pin too before you rotate it.
  final List<String> certPins;

  /// Connect and receive timeout for every API call.
  final Duration apiTimeout;

  static List<String> _parsePins(String raw) => [
    for (final part in raw.split(','))
      if (part.trim().isNotEmpty) _parsePin(part),
  ];

  static String _parsePin(String raw) {
    final pin = raw.trim().replaceAll(':', '').toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(pin)) {
      throw StateError(
        'CERT_SHA256 entry "${raw.trim()}" is not a SHA-256 hex digest.',
      );
    }
    return pin;
  }

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
