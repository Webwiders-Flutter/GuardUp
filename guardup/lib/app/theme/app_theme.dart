import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/textstyle_extension.dart';
import '/app/theme/app_text_theme.dart';
import '/app/theme/colors/color_extenstion.dart';
import 'colors/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      extensions: const [
        AppThemeColors(
          primaryContainer: AppColors.primaryContainer,
          gold: AppColors.gold,
          surfaceDim: AppColors.surfaceDim,
          surfaceContainer: AppColors.surfaceContainer,
          surfaceContainerHigh: AppColors.surfaceContainerHigh,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          onSurfaceTertiary: AppColors.onSurfaceTertiary,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
          errorContainer: AppColors.errorContainer,
          success: AppColors.success,
          successContainer: AppColors.successContainer,
          warning: AppColors.warning,
          warningContainer: AppColors.warningContainer,
          info: AppColors.info,
          infoContainer: AppColors.infoContainer,
        ),
      ],
      scaffoldBackgroundColor: AppColors.transparent,
      textTheme: AppTextTheme.lightTextTheme,
      fontFamily: AppTextTheme.primaryFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        actionsIconTheme: const IconThemeData(color: AppColors.onSurface),
        centerTitle: true,
        foregroundColor: AppColors.onSurface,
        titleTextStyle: AppTextTheme.lightTextTheme.titleMedium?.colour(
          AppColors.onSurface,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onPrimary;
          }
          return AppColors.onSurfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.outlineVariant),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.outlineVariant;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.outline;
        }),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        selectedIconTheme: IconThemeData(size: 24, color: AppColors.primary),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: AppColors.onSurfaceVariant,
        ),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      dividerColor: AppColors.outlineVariant,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextTheme.lightTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextTheme.lightTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextTheme.lightTextTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: AppColors.onSurface,
        hintStyle: AppTextTheme.lightTextTheme.bodyMedium?.colour(
          AppColors.outline,
        ),
        prefixIconConstraints: const BoxConstraints(
          maxWidth: AppSpacing.xxl + AppSpacing.xl,
          minWidth: AppSpacing.xxl + AppSpacing.xl,
        ),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.mlg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: AppTextTheme.lightTextTheme.bodyMedium?.colour(
          AppColors.onSurface,
        ),
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 8,
        shadowColor: AppColors.surfaceDim.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        textStyle: AppTextTheme.lightTextTheme.bodyMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        iconColor: AppColors.onSurfaceVariant,
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
