import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain on iOS, Keystore-wrapped AES-GCM on Android. Holds secrets only;
/// everything else goes in `Prefs`.
class SecureStore {
  SecureStore([
    this._storage = const FlutterSecureStorage(
      // Android keeps the flutter_secure_storage 10 default: a Keystore
      // RSA-OAEP key wraps an AES-GCM key. encryptedSharedPreferences is
      // deprecated, and resetOnError wipes data it can no longer decrypt.
      //
      // this_device keeps the Keychain item out of iCloud and device
      // migration, the iOS side of the Android allowBackup="false".
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  ]);

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}
