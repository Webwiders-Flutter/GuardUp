import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Gold Palette (matching GuardUp mobile app #EDCC73, #AC7F42)
  static const Color primary = Color(0xFFEDCC73); // Luxury Gold
  static const Color primaryContainer = Color(0xFFAC7F42);
  static const Color onPrimary = Color(0xFF191B23);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // Secondary Slate Palette (#262D3D, #333C4F)
  static const Color secondary = Color(0xFF262D3D);
  static const Color secondaryLight = Color(0xFF333C4F);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFFEDCC73);
  static const Color lightTeal = Color(0xFFD3C4B0);
  static const Color purpleLight = Color(0xFFAC7F42);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color darkGreen = Color(0xFF059669);
  static const Color successLight = Color(0x2610B981);
  static const Color warning = Color(0xFFEDCC73);
  static const Color warningLight = Color(0x26EDCC73);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0x26DC2626);
  static const Color info = Color(0xFF7E8B9B);
  static const Color infoLight = Color(0x267E8B9B);

  // Neutrals
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Navigation Sidebar (Executive Midnight Obsidian)
  static const Color sidebarBackground = Color(0xFF0A0D14);

  // Surfaces & Backgrounds (Dark luxury obsidian)
  static const Color backgroundLight = Color(0xFF0E1119);
  static const Color surfaceLight = Color(0xFF191B23);

  // Dark surfaces
  static const Color backgroundDark = Color(0xFF0E1119);
  static const Color surfaceDark = Color(0xFF191B23);

  // Text
  static const Color textPrimaryLight = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0xFFCCCCCC);

  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFFD3C4B0);

  // Border / Divider
  static const Color borderLight = Color(0xFF32353D);
  static const Color borderDark = Color(0xFF262D3D);
  static const Color borderExtraLight = Color(0xFF1F2430);

  // misc.
  static const Color transparent = Colors.transparent;
}
