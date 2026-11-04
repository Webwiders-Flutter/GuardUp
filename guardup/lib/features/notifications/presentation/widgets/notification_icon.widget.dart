import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:guardup/core/extensions/context.extension.dart';

/// A standard notification icon action widget (e.g. for app bars, navigation headers).
/// Automatically observes the live unread count and renders an indicator badge.
/// Tapping defaults to opening [AppRoutes.notifications] unless an explicit [onTap] is provided.
class NotificationIconWidget extends StatelessWidget {
  /// Callback executed when the icon is pressed.
  /// Defaults to navigating to [AppRoutes.notifications].
  final VoidCallback? onTap;

  /// Icon to display (defaults to [Icons.notifications_outlined]).
  final IconData icon;

  /// Custom icon color (defaults to [context.colors.onSurface] or app bar theme).
  final Color? iconColor;

  /// Size of the icon (defaults to 24).
  final double iconSize;

  /// Optional tooltip message.
  final String tooltip;

  /// Optional count override. If null, automatically reads [unreadNotificationCountControllerProvider].
  final int? count;

  /// Custom background color for the badge (defaults to [context.colors.error]).
  final Color? badgeColor;

  /// Custom text color for the badge count (defaults to [context.colors.white]).
  final Color? badgeTextColor;

  const NotificationIconWidget({
    super.key,
    this.onTap,
    this.icon = Icons.notifications_outlined,
    this.iconColor,
    this.iconSize = 28,
    this.tooltip = 'Notifications',
    this.count,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = count;

    final button = IconButton(
      padding: EdgeInsets.zero,
      visualDensity: .compact,
      icon: Icon(
        icon,
        color: iconColor ?? context.colors.onSurface,
        size: iconSize,
      ),
      onPressed: onTap ?? () => context.push(AppRoutes.notifications),
      tooltip: tooltip,
    );

    if (unreadCount != null && unreadCount > 0) {
      return Badge.count(
        count: unreadCount,
        backgroundColor: badgeColor ?? context.colors.error,
        textColor: badgeTextColor ?? context.colors.onSurface,
        maxCount: 99,
        alignment: .topRight,
        largeSize: 16,
        smallSize: 8,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        offset: const Offset(-2, -2),
        child: button,
      );
    }

    return button;
  }
}
