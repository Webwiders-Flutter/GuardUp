import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/theme/colors/color_accessor.dart';
import '/features/booking/presentation/screens/bookings_screen.dart';
import '/features/chat/presentation/screens/conversations_screen.dart';
import '/features/customer/presentation/screens/customer_home_screen.dart';
import '/features/notifications/presentation/screens/notifications_screen.dart';
import '/features/auth/presentation/screens/profile_screen.dart';

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
        go(CustomerHomeScreen.route);
      case 1:
        go(BookingsScreen.route);
      case 2:
        go(ConversationsScreen.route);
      case 3:
        go(NotificationsScreen.route);
      case 4:
        go(ProfileScreen.route);
    }
  }
}
