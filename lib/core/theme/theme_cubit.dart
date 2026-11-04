import 'package:corestone/core/storage/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(ThemeMode.system);

  static const key = 'theme_mode';

  final Prefs _prefs;

  Future<void> load() async {
    final saved = await _prefs.getString(key);
    emit(ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system);
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(key, mode.name);
  }
}
