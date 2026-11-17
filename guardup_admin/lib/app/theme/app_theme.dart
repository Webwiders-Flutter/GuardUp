import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';

import '/core/constants/app_spacing.dart';
import '/app/theme/app_text_theme.dart';
import '/app/theme/colors/color_extenstion.dart';
import '../../core/extensions/textstyle_extension.dart';
import 'colors/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      extensions: const [
        AppThemeColors(
          success: AppColors.success,
          successLight: AppColors.successLight,
          warning: AppColors.warning,
          warningLight: AppColors.warningLight,
          info: AppColors.info,
          infoLight: AppColors.infoLight,
          error: AppColors.error,
          errorLight: AppColors.errorLight,
          onSurfaceSecondary: AppColors.textSecondaryLight,
          borderLight: AppColors.borderLight,
          borderDark: AppColors.borderDark,
          backgroundLight: AppColors.backgroundLight,
          backgroundDark: AppColors.backgroundDark,
          secondaryLight: AppColors.secondaryLight,
          purpleLight: AppColors.purpleLight,
          borderExtraLight: AppColors.borderExtraLight,
        ),
      ],
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: AppTextTheme.lightTextTheme,
      fontFamily: AppTextTheme.primaryFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actionsIconTheme: const IconThemeData(color: AppColors.white),
        centerTitle: true,
        foregroundColor: AppColors.white,
        titleTextStyle: AppTextTheme.lightTextTheme.titleMedium?.colour(
          AppColors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return AppColors.borderLight;
        }),

        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }

          return AppColors.surfaceLight;
        }),

        trackOutlineColor: WidgetStateProperty.all(AppColors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.borderLight.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary.withValues(alpha: 0.08);
          }
          return AppColors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.secondary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return AppColors.secondary.withValues(alpha: 0.12);
          }
          return AppColors.transparent;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: AppColors.borderLight.withValues(alpha: 0.6),
              width: 1.5,
            );
          }
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: AppColors.secondary, width: 1.5);
          }
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: AppColors.secondary, width: 1.5);
          }
          return const BorderSide(color: AppColors.borderLight, width: 1.5);
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical: VisualDensity.minimumDensity,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.borderLight.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary;
          }
          return AppColors.borderLight;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.secondary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return AppColors.secondary.withValues(alpha: 0.12);
          }
          return AppColors.transparent;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical: VisualDensity.minimumDensity,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.white,
        selectedIconTheme: IconThemeData(size: 24, color: AppColors.white),
        unselectedIconTheme: IconThemeData(size: 24, color: AppColors.white),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      dividerColor: AppColors.borderLight,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 4,
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

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          side: const BorderSide(color: AppColors.borderLight),
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
        filled: true,
        fillColor: AppColors.surfaceLight,
        hintStyle: AppTextTheme.lightTextTheme.bodyMedium?.colour(
          AppColors.textSecondaryLight,
        ),
        prefixIconConstraints: const BoxConstraints(
          maxWidth: AppSpacing.xxl + AppSpacing.xl,
          minWidth: AppSpacing.xxl + AppSpacing.xl,
        ),

        alignLabelWithHint: true,
        contentPadding: EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.borderLight),
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
        backgroundColor: AppColors.backgroundDark,
        contentTextStyle: AppTextTheme.lightTextTheme.bodyMedium?.colour(
          AppColors.surfaceLight,
        ),
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceLight,
        surfaceTintColor: AppColors.transparent,
        elevation: 8,
        shadowColor: AppColors.black.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: AppColors.borderLight.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        textStyle: AppTextTheme.lightTextTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
        labelTextStyle: WidgetStatePropertyAll(
          AppTextTheme.lightTextTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: AppColors.textSecondaryLight,
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        titleTextStyle: AppTextTheme.lightTextTheme.titleLarge?.colour(
          AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppTextTheme.lightTextTheme.bodyMedium?.colour(
          AppColors.textSecondaryLight,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: CircleBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      extensions: const [
        AppThemeColors(
          success: AppColors.success,
          successLight: AppColors.successLight,
          warning: AppColors.warning,
          warningLight: AppColors.warningLight,
          info: AppColors.info,
          infoLight: AppColors.infoLight,
          error: AppColors.error,
          errorLight: AppColors.errorLight,
          onSurfaceSecondary: AppColors.textSecondaryDark,
          borderLight: AppColors.borderLight,
          borderDark: AppColors.borderDark,
          backgroundLight: AppColors.backgroundLight,
          backgroundDark: AppColors.backgroundDark,
          secondaryLight: AppColors.secondaryLight,
          purpleLight: AppColors.purpleLight,
          borderExtraLight: AppColors.borderExtraLight,
        ),
      ],
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: AppTextTheme.darkTextTheme,
      fontFamily: AppTextTheme.primaryFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        centerTitle: true,
        foregroundColor: AppColors.textPrimaryDark,
        titleTextStyle: AppTextTheme.darkTextTheme.titleMedium?.colour(
          AppColors.textPrimaryDark,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          return AppColors.borderDark;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.textSecondaryDark;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.borderDark.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary.withValues(alpha: 0.15);
          }
          return AppColors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.secondary.withValues(alpha: 0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.focused)) {
            return AppColors.secondary.withValues(alpha: 0.2);
          }
          return AppColors.transparent;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: AppColors.borderDark.withValues(alpha: 0.6),
              width: 1.5,
            );
          }
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: AppColors.secondary, width: 1.5);
          }
          if (states.contains(WidgetState.hovered)) {
            return const BorderSide(color: AppColors.secondary, width: 1.5);
          }
          return const BorderSide(color: AppColors.borderDark, width: 1.5);
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical: VisualDensity.minimumDensity,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.borderDark.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.secondary;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary;
          }
          return AppColors.borderDark;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.secondary.withValues(alpha: 0.2);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.secondary.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.focused)) {
            return AppColors.secondary.withValues(alpha: 0.2);
          }
          return AppColors.transparent;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical: VisualDensity.minimumDensity,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textSecondaryDark,
        selectedIconTheme: IconThemeData(size: 24, color: AppColors.secondary),
        unselectedIconTheme: IconThemeData(
          size: 24,
          color: AppColors.textSecondaryDark,
        ),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryDark,
        ),
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerColor: AppColors.borderDark,
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
          textStyle: AppTextTheme.darkTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextTheme.darkTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextTheme.darkTextTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        hintStyle: AppTextTheme.darkTextTheme.bodyMedium?.colour(
          AppColors.textSecondaryDark,
        ),
        prefixIconConstraints: const BoxConstraints(
          maxWidth: AppSpacing.xxl + AppSpacing.xl,
          minWidth: AppSpacing.xxl + AppSpacing.xl,
        ),
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
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
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTextTheme.darkTextTheme.bodyMedium?.colour(
          AppColors.textPrimaryDark,
        ),
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: AppColors.transparent,
        elevation: 8,
        shadowColor: AppColors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        textStyle: AppTextTheme.darkTextTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w500,
        ),
        labelTextStyle: WidgetStatePropertyAll(
          AppTextTheme.darkTextTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: AppColors.textSecondaryDark,
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        titleTextStyle: AppTextTheme.darkTextTheme.titleLarge?.colour(
          AppColors.textPrimaryDark,
        ),
        contentTextStyle: AppTextTheme.darkTextTheme.bodyMedium?.colour(
          AppColors.textSecondaryDark,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        shape: CircleBorder(),
      ),
    );
  }
}
