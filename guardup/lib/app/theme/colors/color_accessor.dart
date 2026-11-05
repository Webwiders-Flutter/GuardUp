import 'package:flutter/material.dart';

import '/app/theme/colors/color_extenstion.dart';

/// Semantic accessor for theme colors via [context.colors].
///
/// Follows Material 3 token conventions (primary, surface, onSurface, outline, etc.)
/// rather than raw color names.
class AppThemeAccessor {
  final BuildContext context;

  AppThemeAccessor(this.context);

  ColorScheme get _scheme => Theme.of(context).colorScheme;
  AppThemeColors get _extra => Theme.of(context).extension<AppThemeColors>()!;

  // ------------------------------------------------------------
  // Primary Gold Tokens
  // ------------------------------------------------------------
  /// Luxury Primary Gold (#EDCC73)
  Color get primary => _scheme.primary;

  /// Deep Gold / Bronze Primary Container (#AC7F42)
  Color get primaryContainer => _extra.primaryContainer;

  /// Vibrant Accent Gold (#E5A93C)
  Color get gold => _extra.gold;
  Color get borderColor => _extra.borderColor;

  /// Semantic alias for [gold] (#E5A93C)
  Color get accentGold => _extra.gold;

  /// Content/icon on primary gold (#191B23)
  Color get onPrimary => _scheme.onPrimary;

  /// Content on primaryContainer (#FFFFFF)
  Color get onPrimaryContainer => _scheme.onSurface;

  /// Primary gold gradient (from #EDCC73 to #AC7F42)
  LinearGradient get primaryGradient => LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ------------------------------------------------------------
  // Secondary Tokens
  // ------------------------------------------------------------
  /// Slate secondary surface (#262D3D)
  Color get secondary => _scheme.secondary;

  /// Secondary container (#333C4F)
  Color get secondaryContainer => _extra.surfaceContainerHigh;

  /// Content on secondary (#FFFFFF)
  Color get onSecondary => _scheme.onSecondary;

  // ------------------------------------------------------------
  // Surface & Background Tokens
  // ------------------------------------------------------------
  /// Canvas base background surface (#191B23)
  Color get surface => _scheme.surface;

  /// Midnight Deep Gradient End (#000B14)
  Color get surfaceDim => _extra.surfaceDim;

  /// Card Surface Gradient Start (#1C252D)
  Color get surfaceContainer => _extra.surfaceContainer;

  /// Elevated Card Container Surface (#262D3D)
  Color get surfaceContainerHigh => _extra.surfaceContainerHigh;

  /// Primary text / high-emphasis content on surfaces (#FFFFFF)
  Color get onSurface => _scheme.onSurface;

  /// Secondary text / medium-emphasis labels / icons on surfaces (#CCCCCC)
  Color get onSurfaceVariant => _extra.onSurfaceVariant;

  /// Warm champagne / sand text, icon, and subtle border color (#D3C4B0)
  Color get onSurfaceTertiary => _extra.onSurfaceTertiary;

  /// Semantic alias for [onSurfaceTertiary] (#D3C4B0)
  Color get onSurfaceMuted => _extra.onSurfaceTertiary;

  /// Card surface gradient (from #1C252D to #000B14)
  LinearGradient get surfaceGradient => LinearGradient(
    colors: [surfaceContainer, surfaceDim],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Unselected card subtle gradient
  LinearGradient get surfaceGradientUnselected => LinearGradient(
    colors: [surfaceContainer.withValues(alpha: 0.4), surfaceDim],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ------------------------------------------------------------
  // Outline & Border Tokens
  // ------------------------------------------------------------
  /// Standard outline border (#7E8B9B)
  Color get outline => _extra.outline;

  /// Container outline border (#262D3D)
  Color get outlineVariant => _extra.outlineVariant;

  // ------------------------------------------------------------
  // Feedback & Status Tokens
  // ------------------------------------------------------------
  Color get error => _scheme.error;
  Color get errorContainer => _extra.errorContainer;
  Color get onError => _scheme.onError;

  Color get success => _extra.success;
  Color get successContainer => _extra.successContainer;

  Color get warning => _extra.warning;
  Color get warningContainer => _extra.warningContainer;

  Color get info => _extra.info;
  Color get infoContainer => _extra.infoContainer;

  // ------------------------------------------------------------
  // Misc
  // ------------------------------------------------------------
  Color get transparent => Colors.transparent;
}
