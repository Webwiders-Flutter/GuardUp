import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFEDCC73); // Luxury Gold
  static const Color secondary = Color(0xFFAC7F42); // Deep Gold / Accent
  static const Color onPrimary = Color(0xFF0D0F14); // Near-black text on gold
  static const Color onSecondary = Color(0xFFFFFFFF); // High-contrast text on secondary

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF60A5FA);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Neutrals
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // Light surfaces
  static const Color backgroundLight = Color(0xFFF7F4EE); // Warm ivory-white
  static const Color surfaceLight = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color backgroundDark = Color(0xFF0D0F14); // Deep obsidian
  static const Color surfaceDark = Color(0xFF161920); // Raised obsidian

  // Text
  static const Color textPrimaryLight = Color(0xFF1A1710); // Near-black warm
  static const Color textSecondaryLight = Color(0xFF6B6354); // Warm muted

  static const Color textPrimaryDark = Color(0xFFF5F0E8); // Warm off-white
  static const Color textSecondaryDark = Color(0xFFADA595); // Muted warm gray

  // Border / Divider
  static const Color borderLight = Color(0xFFE0D8C8); // Warm light border
  static const Color borderDark = Color(0xFF2A2D35); // Dark obsidian border
  static const Color borderExtraLight = Color(0xFFF0EAE0); // Subtlest border

  // misc.
  static const Color transparent = Colors.transparent;
}
