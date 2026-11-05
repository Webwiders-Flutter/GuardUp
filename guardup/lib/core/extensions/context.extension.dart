import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/app/theme/colors/color_accessor.dart';

extension ContextExtension on BuildContext {
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;

  TextTheme get textTheme => Theme.of(this).textTheme;

  AppThemeAccessor get colors => AppThemeAccessor(this);

  EdgeInsets get systemPadding => MediaQuery.of(this).padding;

  /// Navigates or jumps to the specified bottom navigation bar tab index in [MainNavigationScreen].
  ///
  /// Index map:
  /// - 0: Home
  /// - 1: Bookings
  /// - 2: Chat
  /// - 3: Alerts
  /// - 4: Profile
  void jumpToNavTab(int index) {
    switch (index) {
      case 0:
        go(AppRoutes.home);
      case 1:
        go(AppRoutes.bookings);
      case 2:
        go(AppRoutes.chat);
      case 3:
        go(AppRoutes.notifications);
      case 4:
        go(AppRoutes.profile);
    }
  }
}
