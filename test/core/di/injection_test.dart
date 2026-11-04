import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/router/app_router.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const testConfig = AppConfig(
  flavor: AppFlavor.dev,
  apiBaseUrl: 'https://api-dev.example.com',
  certSha256: '',
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(sl.reset);

  test('configureDependencies registers every shell service', () async {
    configureDependencies(testConfig);

    expect(sl<AppConfig>(), same(testConfig));
    expect(sl<AppRouter>(), isA<AppRouter>());

    final prefs = sl<Prefs>();
    await prefs.setString('k', 'v');
    expect(await prefs.getString('k'), 'v');
  });
}
