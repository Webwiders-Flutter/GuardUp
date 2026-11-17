import 'package:flutter/widgets.dart';

extension LayoutExtension on BuildContext {
  /// Screen size of current media query
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Screen width
  double get screenWidth => screenSize.width;

  /// Screen height
  double get screenHeight => screenSize.height;

  /// Safe area padding (system padding)
  EdgeInsets get safeAreaPadding => MediaQuery.paddingOf(this);

  /// Responsive breakpoint checks
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  bool get isDesktop => screenWidth >= 1024;

  /// Maximum content width based on responsive breakpoints
  double get maxContentWidth {
    final width = screenWidth;
    if (width > 1200) return 1000;
    if (width > 800) return 700;
    return width;
  }

  /// Centers child widget and constrains it to [maxContentWidth] on large screens
  Widget centeredContent(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: child,
      ),
    );
  }
}

extension LayoutWidgetExtension on Widget {
  /// Centers this widget and constrains it to [context.maxContentWidth]
  Widget centeredContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.maxContentWidth),
        child: this,
      ),
    );
  }
}
