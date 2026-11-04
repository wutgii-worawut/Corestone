import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/storage/secure_store.dart';

const installMarkerKey = 'install_marker';

/// Wipes [secure] on the first launch after an install. The iOS Keychain
/// survives an uninstall but [Prefs] does not, so a missing marker means
/// whatever [secure] holds belongs to an earlier install. Run it before
/// anything reads [secure].
Future<void> wipeSecretsAfterReinstall(Prefs prefs, SecureStore secure) async {
  if (await prefs.getBool(installMarkerKey) ?? false) return;
  try {
    await secure.deleteAll();
  } on Object {
    // Leave the marker unset, so the next launch tries again.
    return;
  }
  await prefs.setBool(installMarkerKey, value: true);
}
