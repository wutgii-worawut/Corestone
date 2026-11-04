enum AppFlavor { dev, stage, prod }

/// The pubspec `version`, which `flutter run` and `flutter build` pass as
/// these defines, so it cannot drift from the store version.
const appVersion =
    '${String.fromEnvironment('FLUTTER_BUILD_NAME')}'
    '+${String.fromEnvironment('FLUTTER_BUILD_NUMBER')}';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.certPins,
    this.demoMode = false,
    this.deepLinkHost = '',
    this.apiTimeout = const Duration(seconds: 15),
  });

  factory AppConfig.fromEnvironment() => AppConfig.parse(const {
    'APP_FLAVOR': String.fromEnvironment('APP_FLAVOR'),
    'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
    'CERT_SHA256': String.fromEnvironment('CERT_SHA256'),
    'DEMO_MODE': String.fromEnvironment('DEMO_MODE'),
    'DEEP_LINK_HOST': String.fromEnvironment('DEEP_LINK_HOST'),
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
    final demoMode = env['DEMO_MODE'] == 'true';
    if (demoMode && flavor != AppFlavor.dev) {
      throw StateError('DEMO_MODE is only for dev, not ${flavor.name}.');
    }
    final deepLinkHost = env['DEEP_LINK_HOST'] ?? '';
    if (deepLinkHost.isNotEmpty &&
        Uri.tryParse('https://$deepLinkHost')?.host != deepLinkHost) {
      throw StateError(
        'DEEP_LINK_HOST "$deepLinkHost" must be a lowercase host name only.',
      );
    }
    return AppConfig(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      certPins: _parsePins(env['CERT_SHA256'] ?? ''),
      demoMode: demoMode,
      deepLinkHost: deepLinkHost,
    );
  }

  final AppFlavor flavor;
  final String apiBaseUrl;

  /// Lowercase hex SHA-256 of the leaf certificate's DER bytes, from the
  /// comma-separated `CERT_SHA256` key. Empty means pinning is off. List the
  /// next certificate's pin too before you rotate it.
  final List<String> certPins;

  /// Signs in, deletes accounts and sends feedback against an in-memory fake
  /// instead of the API, so the template runs with no backend. Dev only.
  final bool demoMode;

  /// The https host this flavor's App Links and Universal Links use, from
  /// `DEEP_LINK_HOST`. Empty turns deep links off. Keep it equal to the
  /// flavor's `deepLinkHost` in Gradle and `DEEP_LINK_HOST` in the xcconfig.
  final String deepLinkHost;

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
