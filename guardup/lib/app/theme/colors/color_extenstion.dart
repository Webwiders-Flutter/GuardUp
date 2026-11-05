import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color primaryContainer;
  final Color gold;
  final Color surfaceDim;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color onSurfaceVariant;
  final Color onSurfaceTertiary;
  final Color outline;
  final Color outlineVariant;
  final Color errorContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;

  const AppThemeColors({
    required this.primaryContainer,
    required this.gold,
    required this.surfaceDim,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.onSurfaceVariant,
    required this.onSurfaceTertiary,
    required this.outline,
    required this.outlineVariant,
    required this.errorContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
  });

  @override
  AppThemeColors copyWith({
    Color? primaryContainer,
    Color? gold,
    Color? surfaceDim,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? onSurfaceVariant,
    Color? onSurfaceTertiary,
    Color? outline,
    Color? outlineVariant,
    Color? errorContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
  }) {
    return AppThemeColors(
      primaryContainer: primaryContainer ?? this.primaryContainer,
      gold: gold ?? this.gold,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      onSurfaceTertiary: onSurfaceTertiary ?? this.onSurfaceTertiary,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      errorContainer: errorContainer ?? this.errorContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;

    return AppThemeColors(
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      gold: Color.lerp(gold, other.gold, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      surfaceContainerHigh: Color.lerp(
        surfaceContainerHigh,
        other.surfaceContainerHigh,
        t,
      )!,
      onSurfaceVariant: Color.lerp(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      )!,
      onSurfaceTertiary: Color.lerp(
        onSurfaceTertiary,
        other.onSurfaceTertiary,
        t,
      )!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
    );
  }
}
