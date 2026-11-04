import 'package:corestone/core/theme/app_colors.dart';
import 'package:corestone/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const seed = Color(0xFF335CFF);

  static final light = _build(Brightness.light, AppColors.light);
  static final dark = _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
      fontFamily: AppTextStyles.fontFamily,
      fontFamilyFallback: AppTextStyles.fontFamilyFallback,
      textTheme: AppTextStyles.textTheme,
      extensions: [colors],
    );
  }
}
