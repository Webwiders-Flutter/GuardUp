import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/app/theme/app_text_theme.dart';
import '/app/theme/colors/color_extenstion.dart';
import '../../core/extensions/textstyle_extension.dart';
import 'colors/app_colors.dart';

/// Per-brightness color set that drives [AppTheme._build].
///
/// Keeping both modes in one builder guarantees every component gets a
/// mode-appropriate color, instead of two hand-maintained copies drifting.
class _Palette {
  final Brightness brightness;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderSubtle;
  final Color error;
  final Color inputFill;
  final Color snackBackground;
  final Color snackForeground;
  final double shadowAlpha;
  final double hoverAlpha;
  final double pressedAlpha;
  final TextTheme textTheme;
  final AppThemeColors extension;

  const _Palette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderSubtle,
    required this.error,
    required this.inputFill,
    required this.snackBackground,
    required this.snackForeground,
    required this.shadowAlpha,
    required this.hoverAlpha,
    required this.pressedAlpha,
    required this.textTheme,
    required this.extension,
  });
}

class AppTheme {
  AppTheme._();

  // ─── Palettes ───────────────────────────────────────────────────────────────

  static final _Palette _light = _Palette(
    brightness: Brightness.light,
    primary: AppColors.primaryDeep,
    onPrimary: AppColors.onPrimaryDeep,
    secondary: AppColors.secondaryDeep,
    onSecondary: AppColors.onSecondaryDeep,
    background: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    surfaceMuted: AppColors.surfaceMutedLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    border: AppColors.borderLight,
    borderSubtle: AppColors.borderExtraLight,
    error: AppColors.error,
    inputFill: AppColors.surfaceLight,
    snackBackground: AppColors.textPrimaryLight,
    snackForeground: AppColors.textPrimaryDark,
    shadowAlpha: 0.08,
    hoverAlpha: 0.08,
    pressedAlpha: 0.12,
    textTheme: AppTextTheme.lightTextTheme,
    extension: const AppThemeColors(
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
      borderExtraLight: AppColors.borderExtraLight,
      backgroundLight: AppColors.backgroundLight,
      backgroundDark: AppColors.backgroundDark,
    ),
  );

  static final _Palette _dark = _Palette(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    surfaceMuted: AppColors.surfaceMutedDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    border: AppColors.borderDark,
    borderSubtle: AppColors.borderExtraDark,
    error: AppColors.errorOnDark,
    inputFill: AppColors.backgroundDark,
    snackBackground: AppColors.surfaceMutedDark,
    snackForeground: AppColors.textPrimaryDark,
    shadowAlpha: 0.35,
    hoverAlpha: 0.1,
    pressedAlpha: 0.2,
    textTheme: AppTextTheme.darkTextTheme,
    extension: const AppThemeColors(
      success: AppColors.successOnDark,
      successLight: AppColors.successTintOnDark,
      warning: AppColors.warningOnDark,
      warningLight: AppColors.warningTintOnDark,
      info: AppColors.infoOnDark,
      infoLight: AppColors.infoTintOnDark,
      error: AppColors.errorOnDark,
      errorLight: AppColors.errorTintOnDark,
      onSurfaceSecondary: AppColors.textSecondaryDark,
      borderLight: AppColors.borderDark,
      borderDark: AppColors.borderDark,
      borderExtraLight: AppColors.borderExtraDark,
      backgroundLight: AppColors.backgroundDark,
      backgroundDark: AppColors.backgroundDark,
    ),
  );

  // ─── Public Themes (built once) ─────────────────────────────────────────────

  static final ThemeData lightTheme = _build(_light);
  static final ThemeData darkTheme = _build(_dark);

  // ─── Builder ────────────────────────────────────────────────────────────────

  static ThemeData _build(_Palette p) {
    final t = p.textTheme;
    final isDark = p.brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primary.withValues(alpha: isDark ? 0.18 : 0.12),
      onPrimaryContainer: p.textPrimary,
      secondary: p.secondary,
      onSecondary: p.onSecondary,
      secondaryContainer: p.secondary.withValues(alpha: isDark ? 0.18 : 0.12),
      onSecondaryContainer: p.textPrimary,
      error: p.error,
      onError: isDark ? AppColors.onPrimary : AppColors.white,
      errorContainer: p.extension.errorLight,
      onErrorContainer: p.error,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceMuted,
      surfaceContainerHigh: p.surfaceMuted,
      surfaceContainerHighest: p.surfaceMuted,
      outline: p.border,
      outlineVariant: p.borderSubtle,
      shadow: AppColors.black,
      scrim: AppColors.black,
      surfaceTint: AppColors.transparent,
      inverseSurface: p.snackBackground,
      onInverseSurface: p.snackForeground,
      inversePrimary: isDark ? AppColors.primaryDeep : AppColors.primary,
    );

    final overlay = WidgetStateProperty.resolveWith<Color>((states) {
      if (states.contains(WidgetState.pressed)) {
        return p.primary.withValues(alpha: p.pressedAlpha);
      }
      if (states.contains(WidgetState.hovered)) {
        return p.primary.withValues(alpha: p.hoverAlpha);
      }
      return AppColors.transparent;
    });

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    const buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.sm,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      extensions: [p.extension],
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      textTheme: t,
      fontFamily: AppTextTheme.primaryFontFamily,
      hoverColor: p.textPrimary.withValues(alpha: 0.04),
      splashColor: p.primary.withValues(alpha: p.hoverAlpha),
      highlightColor: AppColors.transparent,

      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        elevation: 0,
        shadowColor: AppColors.transparent,
        surfaceTintColor: AppColors.transparent,
        iconTheme: IconThemeData(color: p.textPrimary),
        actionsIconTheme: IconThemeData(color: p.textPrimary),
        centerTitle: true,
        foregroundColor: p.textPrimary,
        titleTextStyle: t.titleMedium?.colour(p.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: p.border),
        ),
      ),

      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

      iconTheme: IconThemeData(color: p.textSecondary),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.snackBackground,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: t.bodySmall?.colour(p.snackForeground),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceMuted,
        selectedColor: p.primary.withValues(alpha: isDark ? 0.2 : 0.14),
        side: BorderSide(color: p.border),
        labelStyle: t.labelMedium?.colour(p.textPrimary),
        secondaryLabelStyle: t.labelMedium?.colour(p.primary),
        checkmarkColor: p.primary,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.border,
        circularTrackColor: AppColors.transparent,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.25),
        selectionHandleColor: p.primary,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.textSecondary,
          elevation: 0,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: t.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.textSecondary,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: t.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: t.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: t.labelLarge,
        ),
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.border;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.onPrimary;
          return isDark ? p.textSecondary : AppColors.white;
        }),
        trackOutlineColor: WidgetStateProperty.all(AppColors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.border.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) return p.primary;
          return AppColors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        overlayColor: overlay,
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(
              color: p.border.withValues(alpha: 0.6),
              width: 1.5,
            );
          }
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: p.primary, width: 1.5);
          }
          return BorderSide(
            color: isDark ? p.textSecondary.withValues(alpha: 0.5) : p.border,
            width: 1.5,
          );
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return p.border.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.textSecondary.withValues(alpha: 0.6);
        }),
        overlayColor: overlay,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        hintStyle: t.bodyMedium?.colour(p.textSecondary),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        prefixIconConstraints: const BoxConstraints(
          maxWidth: AppSpacing.xxl + AppSpacing.xl,
          minWidth: AppSpacing.xxl + AppSpacing.xl,
        ),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.borderSubtle),
        focusedBorder: inputBorder(p.primary, 1.5),
        errorBorder: inputBorder(p.error),
        focusedErrorBorder: inputBorder(p.error, 1.5),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.snackBackground,
        contentTextStyle: t.bodyMedium?.colour(p.snackForeground),
        // Snackbars are dark in both modes, so the bright gold reads best.
        actionTextColor: AppColors.primary,
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: isDark ? BorderSide(color: p.border) : BorderSide.none,
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 8,
        shadowColor: AppColors.black.withValues(alpha: p.shadowAlpha),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: p.border),
        ),
        textStyle: t.bodyMedium?.copyWith(
          color: p.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        labelTextStyle: WidgetStatePropertyAll(
          t.bodyMedium?.copyWith(
            color: p.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: p.textSecondary,
        menuPadding: const EdgeInsets.symmetric(vertical: 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: isDark ? 12 : 8,
        shadowColor: AppColors.black.withValues(alpha: p.shadowAlpha),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: t.titleLarge?.colour(p.textPrimary),
        contentTextStyle: t.bodyMedium?.colour(p.textSecondary),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: const CircleBorder(),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textSecondary,
        selectedIconTheme: IconThemeData(size: 24, color: p.primary),
        unselectedIconTheme: IconThemeData(size: 24, color: p.textSecondary),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: p.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.textSecondary,
        ),
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
