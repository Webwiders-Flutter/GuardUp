final class AppDurations {
  AppDurations._();

  /// Hover / press feedback.
  static const instant = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 200);

  /// Expand / collapse and layout transitions.
  static const normal = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}
