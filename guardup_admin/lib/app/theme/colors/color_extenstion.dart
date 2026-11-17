import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color info;
  final Color infoLight;
  final Color error;
  final Color errorLight;
  final Color onSurfaceSecondary;
  final Color borderLight;
  final Color borderDark;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color secondaryLight;
  final Color purpleLight;
  final Color borderExtraLight;

  const AppThemeColors({
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.info,
    required this.infoLight,
    required this.error,
    required this.errorLight,
    required this.onSurfaceSecondary,
    required this.borderLight,
    required this.borderDark,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.secondaryLight,
    required this.purpleLight,
    required this.borderExtraLight,
  });

  Color get lightTeal => secondaryLight;

  // --------------------------------------------------
  // copyWith
  // --------------------------------------------------
  @override
  AppThemeColors copyWith({
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? info,
    Color? infoLight,
    Color? error,
    Color? errorLight,
    Color? onSurfaceSecondary,
    Color? borderLight,
    Color? borderDark,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? secondaryLight,
    Color? purpleLight,
    Color? borderExtraLight,
  }) {
    return AppThemeColors(
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      onSurfaceSecondary: onSurfaceSecondary ?? this.onSurfaceSecondary,
      borderLight: borderLight ?? this.borderLight,
      borderDark: borderDark ?? this.borderDark,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      purpleLight: purpleLight ?? this.purpleLight,
      borderExtraLight: borderExtraLight ?? this.borderExtraLight,
    );
  }

  // --------------------------------------------------
  // lerp (needed for theme animation)
  // --------------------------------------------------
  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      onSurfaceSecondary: Color.lerp(
        onSurfaceSecondary,
        other.onSurfaceSecondary,
        t,
      )!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderDark: Color.lerp(borderDark, other.borderDark, t)!,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      backgroundDark: Color.lerp(backgroundDark, other.backgroundDark, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      purpleLight: Color.lerp(purpleLight, other.purpleLight, t)!,
      borderExtraLight: Color.lerp(
        borderExtraLight,
        other.borderExtraLight,
        t,
      )!,
    );
  }
}
