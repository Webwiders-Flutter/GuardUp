import 'package:flutter/material.dart';

/// Semantic Material 3 color tokens for the GuardUp design system.
///
/// Follows Material 3 token naming conventions (primary, surface, onSurface,
/// outline, etc.) instead of literal/vague names.
final class AppColors {
  AppColors._();

  // ------------------------------------------------------------
  // Primary Gold Palette (#EDCC73, #AC7F42, #E5A93C)
  // ------------------------------------------------------------
  /// Luxury Primary Gold (#EDCC73)
  static const Color primary = Color(0xFFEDCC73);

  /// Deep Gold / Bronze Primary Container (#AC7F42)
  static const Color primaryContainer = Color(0xFFAC7F42);

  /// Vibrant Accent Gold (#E5A93C)
  static const Color gold = Color(0xFFE5A93C);
  static const Color borderColor = Color(0xFF32353D);

  /// High-contrast label on primary (#191B23)
  static const Color onPrimary = Color(0xFF191B23);

  /// High-contrast label on primaryContainer (#FFFFFF)
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // ------------------------------------------------------------
  // Secondary Slate Palette (#262D3D, #333C4F)
  // ------------------------------------------------------------
  /// Slate Secondary (#262D3D)
  static const Color secondary = Color(0xFF262D3D);

  /// Slate Secondary Container (#333C4F)
  static const Color secondaryContainer = Color(0xFF333C4F);

  /// Label on secondary (#FFFFFF)
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ------------------------------------------------------------
  // Surfaces & Backgrounds (#191B23, #1C252D, #000B14)
  // ------------------------------------------------------------
  /// Deep Dark Canvas / Background (#191B23)
  static const Color surface = Color(0xFF191B23);

  /// Midnight Deep Gradient End (#000B14)
  static const Color surfaceDim = Color(0xFF000B14);

  /// Card Surface Gradient Start (#1C252D)
  static const Color surfaceContainer = Color(0xFF1C252D);

  /// Elevated Card Container Surface (#262D3D)
  static const Color surfaceContainerHigh = Color(0xFF262D3D);

  /// Primary white text on surfaces (#FFFFFF)
  static const Color onSurface = Color(0xFFFFFFFF);

  /// Secondary muted text on surfaces (#CCCCCC)
  static const Color onSurfaceVariant = Color(0xFFCCCCCC);

  /// Warm champagne / sand text, icon, and subtle border color (#D3C4B0)
  static const Color onSurfaceTertiary = Color(0xFFD3C4B0);

  /// Semantic alias for [onSurfaceTertiary]
  static const Color onSurfaceMuted = onSurfaceTertiary;

  // ------------------------------------------------------------
  // Outlines & Borders (#7E8B9B, #262D3D)
  // ------------------------------------------------------------
  /// Border outline (#7E8B9B)
  static const Color outline = Color(0xFF7E8B9B);

  /// Subtle container outline (#262D3D)
  static const Color outlineVariant = Color(0xFF262D3D);

  // ------------------------------------------------------------
  // Feedback & Status Colors
  // ------------------------------------------------------------
  /// Alert Coral Red (#FF7D7D)
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0x1AFF0000);
  static const Color onError = Color(0xFFFFFFFF);

  /// Vibrant Verified Green (#67FA99)
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0x2667FA99);
  static const Color onSuccess = Color(0xFF191B23);

  /// Warning Gold (#EDCC73)
  static const Color warning = Color(0xFFEDCC73);
  static const Color warningContainer = Color(0x26EDCC73);
  static const Color onWarning = Color(0xFF191B23);

  /// Info Slate (#7E8B9B)
  static const Color info = Color(0xFF7E8B9B);
  static const Color infoContainer = Color(0x267E8B9B);
  static const Color onInfo = Color(0xFFFFFFFF);

  // ------------------------------------------------------------
  // Misc
  // ------------------------------------------------------------
  static const Color transparent = Colors.transparent;
}
