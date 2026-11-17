import 'package:flutter/material.dart';

import '/app/theme/colors/color_accessor.dart';

extension ContextExtension on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;

  TextTheme get textTheme => Theme.of(this).textTheme;

  AppThemeAccessor get colors => AppThemeAccessor(this);

  EdgeInsets get systemPadding => MediaQuery.of(this).padding;
}
