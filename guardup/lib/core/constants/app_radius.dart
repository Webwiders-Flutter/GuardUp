import 'package:flutter/widgets.dart';
/// Centralized corner radius design tokens.
final class AppRadius {
  AppRadius._();

  /// 0.0 - Sharp edges
  static const double none = 0;

  /// 4.0 - Extra small radius / badges, chips
  static const double xs = 4;

  /// 6.0 - Sub-small radius
  static const double ssm = 6;

  /// 8.0 - Small radius / buttons, standard cards
  static const double sm = 8;

  /// 12.0 - Medium radius / containers, text fields
  static const double md = 12;

  /// 16.0 - Large radius / dialogs, surface cards
  static const double lg = 16;

  /// 20.0 - Extra large radius / bottom sheets
  static const double xl = 20;

  /// 24.0 - Double extra large radius / hero panels
  static const double xxl = 24;

  /// 28.0 - Rounded cards & floating action items
  static const double round = 28;

  /// 999.0 - Fully rounded pill / circle
  static const double full = 999;

  // ── Pre-resolved BorderRadius instances ────────────────────────────────────
  static const BorderRadius bNone = BorderRadius.zero;
  static final BorderRadius bXs = BorderRadius.circular(xs);
  static final BorderRadius bSm = BorderRadius.circular(sm);
  static final BorderRadius bMd = BorderRadius.circular(md);
  static final BorderRadius bLg = BorderRadius.circular(lg);
  static final BorderRadius bXl = BorderRadius.circular(xl);
  static final BorderRadius bXxl = BorderRadius.circular(xxl);
  static final BorderRadius bRound = BorderRadius.circular(round);
  static final BorderRadius bFull = BorderRadius.circular(full);
}
