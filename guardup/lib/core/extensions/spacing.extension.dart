import 'package:flutter/widgets.dart';

extension SpaceExtension on num {
  /// Vertical spacing: `SizedBox(height: ...)`
  SizedBox get h => SizedBox(height: toDouble());

  /// Horizontal spacing: `SizedBox(width: ...)`
  SizedBox get w => SizedBox(width: toDouble());

  /// Symmetric vertical padding: `EdgeInsets.symmetric(vertical: ...)`
  EdgeInsets get yPadding => EdgeInsets.symmetric(vertical: toDouble());

  /// Symmetric horizontal padding: `EdgeInsets.symmetric(horizontal: ...)`
  EdgeInsets get xPadding => EdgeInsets.symmetric(horizontal: toDouble());

  /// All sides padding: `EdgeInsets.all(...)`
  EdgeInsets get allPadding => EdgeInsets.all(toDouble());

  /// Shorthands for EdgeInsets.only
  EdgeInsets get tPadding => EdgeInsets.only(top: toDouble());
  EdgeInsets get bPadding => EdgeInsets.only(bottom: toDouble());
  EdgeInsets get lPadding => EdgeInsets.only(left: toDouble());
  EdgeInsets get rPadding => EdgeInsets.only(right: toDouble());

  /// Returns this percentage of the screen width (0 to 100).
  /// Example: `50.wPercent(context)` returns 50% of screen width.
  double wPercent(BuildContext context) =>
      MediaQuery.sizeOf(context).width * (toDouble() / 100);

  /// Returns this percentage of the screen height (0 to 100).
  /// Example: `50.hPercent(context)` returns 50% of screen height.
  double hPercent(BuildContext context) =>
      MediaQuery.sizeOf(context).height * (toDouble() / 100);
}

extension SpacingContextExtension on BuildContext {
  /// Default horizontal padding (4% of screen width)
  double get horizontalScreenPadding => 4.wPercent(this);

  /// Optional vertical padding (3% of screen height)
  double get verticalScreenPadding => 3.hPercent(this);

  /// Combined screen padding
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: horizontalScreenPadding,
    vertical: verticalScreenPadding,
  );

  /// Only horizontal screen padding
  EdgeInsets get horizontalEdgeInsets => horizontalScreenPadding.xPadding;

  /// Only vertical screen padding
  EdgeInsets get verticalEdgeInsets => verticalScreenPadding.yPadding;
}
