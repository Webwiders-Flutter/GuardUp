import 'package:flutter/material.dart';

import '/app/theme/colors/app_colors.dart';
import '/app/theme/colors/color_extenstion.dart';

class AppThemeAccessor {
  final BuildContext context;

  AppThemeAccessor(this.context);

  ColorScheme get _scheme => Theme.of(context).colorScheme;
  AppThemeColors get _extra => Theme.of(context).extension<AppThemeColors>()!;

  /// Material colors
  Color get primary => _scheme.primary;
  Color get onPrimary => _scheme.onPrimary;
  Color get secondary => _scheme.secondary;
  Color get surface => _scheme.surface;
  Color get onSurface => _scheme.onSurface;
  Color get error => _scheme.error;

  /// Custom colors
  Color get success => _extra.success;
  Color get successLight => _extra.successLight;
  Color get warning => _extra.warning;
  Color get warningLight => _extra.warningLight;
  Color get info => _extra.info;
  Color get infoLight => _extra.infoLight;
  Color get errorLight => _extra.errorLight;

  Color get borderLight => _extra.borderLight;
  Color get borderDark => _extra.borderDark;
  Color get onSurfaceSecondary => _extra.onSurfaceSecondary;
  Color get backgroundLight => _extra.backgroundLight;
  Color get backgroundDark => _extra.backgroundDark;
  Color get secondaryLight => _extra.secondaryLight;
  Color get lightTeal => _extra.secondaryLight;
  Color get purpleLight => _extra.purpleLight;
  Color get borderExtraLight => _extra.borderExtraLight;
  Color get transparent => Colors.transparent;
  Color get white => AppColors.white;
  Color get black => AppColors.black;
}
