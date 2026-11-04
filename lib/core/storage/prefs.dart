import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  const Prefs(this._prefs);

  final SharedPreferencesAsync _prefs;

  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  Future<bool?> getBool(String key) => _prefs.getBool(key);

  Future<double?> getDouble(String key) => _prefs.getDouble(key);

  Future<int?> getInt(String key) => _prefs.getInt(key);

  Future<String?> getString(String key) => _prefs.getString(key);

  Future<List<String>?> getStringList(String key) =>
      _prefs.getStringList(key);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
