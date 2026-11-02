import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ------------------------------------------------------------
  // Brand / Theme Colors (GuardUp Premium Security Palette)
  // ------------------------------------------------------------
  /// Luxury Gold Primary Accent (#EDBD69)
  static const Color primary = Color(0xFFEDBD69);
  static const Color primaryLight = Color(0xFFF3D295);
  static const Color primaryDark = Color(0xFFD4A44C);

  /// High-contrast text on primary gold CTA (#191B23)
  static const Color onPrimary = Color(0xFF191B23);

  /// Dark Slate Container / Card Surface (#262D3D)
  static const Color secondary = Color(0xFF262D3D);
  static const Color secondaryLight = Color(0xFF333C4F);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ------------------------------------------------------------
  // Status Colors
  // ------------------------------------------------------------
  /// Vibrant Active / Verified Green (#67FA99)
  static const Color success = Color(0xFF67FA99);
  static const Color successLight = Color(0x2667FA99); // 15% opacity green
  static const Color onSuccess = Color(0xFF191B23);

  /// Gold Warning (#EDBD69)
  static const Color warning = Color(0xFFEDBD69);
  static const Color warningLight = Color(0x26EDBD69);
  static const Color onWarning = Color(0xFF191B23);

  /// Alert / Error Coral Red (#FF7D7D)
  static const Color error = Color(0xFFFF7D7D);

  /// Translucent Red Alert Background (#FF00001A = 10% opacity pure red)
  static const Color errorLight = Color(0x1AFF0000);
  static const Color onError = Color(0xFFFFFFFF);

  /// Muted Slate Info (#7E8B9B)
  static const Color info = Color(0xFF7E8B9B);
  static const Color infoLight = Color(0x267E8B9B);
  static const Color onInfo = Color(0xFFFFFFFF);

  // ------------------------------------------------------------
  // Neutrals & Surfaces
  // ------------------------------------------------------------
  /// Pure White (#FFFFFF)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Deep Dark Canvas / Background (#191B23)
  static const Color background = Color(0xFF191B23);
  static const Color backgroundLight = Color(0xFF191B23);
  static const Color backgroundDark = Color(0xFF191B23);
  static const Color onBackground = Color(0xFFFFFFFF);

  /// Slate Card / Container Surface (#262D3D)
  static const Color surface = Color(0xFF262D3D);
  static const Color surfaceLight = Color(0xFF262D3D);
  static const Color surfaceDark = Color(0xFF262D3D);
  static const Color onSurface = Color(0xFFFFFFFF);

  // ------------------------------------------------------------
  // Typography Colors
  // ------------------------------------------------------------
  /// High-contrast primary text (#FFFFFF)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  /// Subtitle / Secondary label text (#7E8B9B)
  static const Color textSecondary = Color(0xFF7E8B9B);
  static const Color textSecondaryLight = Color(0xFF7E8B9B);
  static const Color textSecondaryDark = Color(0xFF7E8B9B);

  // ------------------------------------------------------------
  // Borders & Dividers
  // ------------------------------------------------------------
  /// Slate border (#7E8B9B)
  static const Color border = Color(0xFF7E8B9B);
  static const Color borderLight = Color(0x337E8B9B); // ~20% opacity border
  static const Color borderDark = Color(0xFF262D3D);
  static const Color borderExtraLight = Color(0x1F7E8B9B); // Subtle divider

  // Aliases for compatibility
  static const Color darkGreen = Color(0xFF67FA99);
  static const Color teal = Color(0xFFEDBD69);
  static const Color lightTeal = Color(0xFF67FA99);
  static const Color purpleLight = Color(0xFFEDBD69);

  // Misc
  static const Color transparent = Colors.transparent;
}
