import 'package:flutter/material.dart';

/// Brand tokens Material 3's [ColorScheme] has no slot for.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  static const light = AppColors(
    success: Color(0xFF16A34A),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFD97706),
    onWarning: Color(0xFFFFFFFF),
    shimmerBase: Color(0xFFE3E3E3),
    shimmerHighlight: Color(0xFFF5F5F5),
  );

  static const dark = AppColors(
    success: Color(0xFF4ADE80),
    onSuccess: Color(0xFF052E16),
    warning: Color(0xFFFBBF24),
    onWarning: Color(0xFF451A03),
    shimmerBase: Color(0xFF303130),
    shimmerHighlight: Color(0xFF414241),
  );

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color shimmerBase;
  final Color shimmerHighlight;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
