import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The app language. A null state follows the device locale.
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit(this._prefs) : super(null);

  static const key = 'locale';

  final Prefs _prefs;

  Future<void> load() async {
    final saved = await _prefs.getString(key);
    emit(_supported(saved));
  }

  Future<void> setLocale(Locale? locale) async {
    emit(locale);
    if (locale == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, locale.languageCode);
    }
  }

  static Locale? _supported(String? languageCode) {
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == languageCode) return locale;
    }
    return null;
  }
}
