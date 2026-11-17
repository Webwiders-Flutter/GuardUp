import 'package:flutter/material.dart';

/// Raw color tokens.
///
/// Widgets should read colors through `context.colors` (theme-aware) rather
/// than these constants, so they adapt to light and dark mode automatically.
///
/// Light-mode foregrounds are tuned to reach ~4.5:1 contrast (WCAG AA) on
/// white/ivory; dark-mode foregrounds are brighter so they read on obsidian.
class AppColors {
  AppColors._();

  // ── Brand · Dark mode (also used by the always-dark sidebar) ───────────────
  static const Color primary = Color(0xFFEDCC73); // Luxury gold
  static const Color onPrimary = Color(0xFF0D0F14); // Near-black on gold
  static const Color secondary = Color(0xFFC9A063); // Soft antique gold
  static const Color onSecondary = Color(0xFF0D0F14);

  // ── Brand · Light mode (deeper gold so it stays readable on white) ─────────
  static const Color primaryDeep = Color(0xFF8C6A18); // Burnished gold
  static const Color onPrimaryDeep = Color(0xFFFFFFFF);
  static const Color secondaryDeep = Color(0xFF86612B); // Bronze
  static const Color onSecondaryDeep = Color(0xFFFFFFFF);

  // ── Status · Light mode (foreground + pale tint background) ────────────────
  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Status · Dark mode (bright foreground + deep tint background) ──────────
  static const Color successOnDark = Color(0xFF4ADE80);
  static const Color successTintOnDark = Color(0xFF12291C);
  static const Color warningOnDark = Color(0xFFFBBF24);
  static const Color warningTintOnDark = Color(0xFF2E2410);
  static const Color errorOnDark = Color(0xFFF87171);
  static const Color errorTintOnDark = Color(0xFF341719);
  static const Color infoOnDark = Color(0xFF60A5FA);
  static const Color infoTintOnDark = Color(0xFF132339);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF7F4EE); // Warm ivory
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFFBF9F5); // Hover / zebra

  // ── Dark surfaces ──────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0D0F14); // Deep obsidian
  static const Color surfaceDark = Color(0xFF161920); // Raised obsidian
  static const Color surfaceMutedDark = Color(0xFF1C2029); // Hover / zebra

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1710); // Near-black warm
  static const Color textSecondaryLight = Color(0xFF6B6354); // Warm muted
  static const Color textPrimaryDark = Color(0xFFF5F0E8); // Warm off-white
  static const Color textSecondaryDark = Color(0xFFADA595); // Muted warm gray

  // ── Borders ────────────────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE0D8C8); // Warm light border
  static const Color borderExtraLight = Color(0xFFF0EAE0); // Subtlest border
  static const Color borderDark = Color(0xFF2A2D35); // Obsidian border
  static const Color borderExtraDark = Color(
    0xFF22252C,
  ); // Subtlest dark border
}
