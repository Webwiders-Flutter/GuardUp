/// Centralized animation and timeout duration tokens.
final class AppDurations {
  AppDurations._();

  /// 100ms - Ultra-fast micro-interactions, ripples, quick badge reveals
  static const fastest = Duration(milliseconds: 100);

  /// 200ms - Fast UI feedback, toggle switches, hover effects
  static const fast = Duration(milliseconds: 200);

  /// 250ms - Standard image fades and subtle view transitions
  static const normal = Duration(milliseconds: 250);

  /// 300ms - Medium animations, bottom sheets, dialog scales
  static const medium = Duration(milliseconds: 300);

  /// 500ms - Deliberate transitions, expand/collapse accordions
  static const slow = Duration(milliseconds: 500);

  /// 800ms - Emphasized loading loops and attention animations
  static const slower = Duration(milliseconds: 800);

  /// 3s - Short duration snackbars
  static const snackbarShort = Duration(seconds: 3);

  /// 4s - Standard snackbar visibility
  static const snackbar = Duration(seconds: 4);
}
