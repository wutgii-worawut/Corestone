import 'package:corestone/core/storage/install_marker.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late Prefs prefs;
  final secure = SecureStore();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = Prefs(SharedPreferencesAsync());
    // A Keychain item left behind by an uninstalled copy of the app.
    FlutterSecureStorage.setMockInitialValues({'auth_tokens': 'old'});
  });

  test('the first launch after an install wipes secure storage', () async {
    await wipeSecretsAfterReinstall(prefs, secure);
    expect(await secure.read('auth_tokens'), isNull);
    expect(await prefs.getBool(installMarkerKey), isTrue);
  });

  test('later launches keep secure storage', () async {
    await wipeSecretsAfterReinstall(prefs, secure);
    await secure.write('auth_tokens', 'new');
    await wipeSecretsAfterReinstall(prefs, secure);
    expect(await secure.read('auth_tokens'), 'new');
  });
}
