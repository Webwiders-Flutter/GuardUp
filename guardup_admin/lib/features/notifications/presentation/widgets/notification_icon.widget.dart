import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/core/extensions/context.extension.dart';
import '/features/notifications/di/notification.providers.dart';
import '/features/notifications/presentation/screens/notification_management.screen.dart';
import '/shared/widgets/buttons/app_icon_button.dart';
import '/shared/widgets/misc/app_badge.dart';

/// A standard notification icon action widget (e.g. for app bars, navigation headers).
/// Automatically observes the live unread count and renders an indicator badge.
/// Tapping defaults to opening [NotificationManagementScreen.route] unless an explicit [onTap] is provided.
class NotificationIconWidget extends ConsumerWidget {
  /// Callback executed when the icon is pressed.
  /// Defaults to navigating to [NotificationManagementScreen.route].
  final VoidCallback? onTap;

  /// Icon to display (defaults to [Icons.notifications_outlined]).
  final IconData icon;

  /// Custom icon color (defaults to [context.colors.onSurfaceSecondary]).
  final Color? iconColor;

  /// Optional tooltip message.
  final String tooltip;

  /// Optional count override. If null, automatically reads [unreadNotificationCountControllerProvider].
  final int? count;

  /// Custom background color for the badge (defaults to [context.colors.error]).
  final Color? badgeColor;

  /// Custom text color for the badge count (defaults to [context.colors.white]).
  final Color? badgeTextColor;

  /// Visual treatment of the button.
  final AppIconButtonVariant variant;

  /// Size of the button.
  final AppIconButtonSize size;

  const NotificationIconWidget({
    super.key,
    this.onTap,
    this.icon = Icons.notifications_outlined,
    this.iconColor,
    this.tooltip = 'Notifications',
    this.count,
    this.badgeColor,
    this.badgeTextColor,
    this.variant = AppIconButtonVariant.outlined,
    this.size = AppIconButtonSize.medium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        count ??
        (ref.watch(unreadNotificationCountControllerProvider).value ?? 0);

    final location = GoRouterState.of(context).uri.path;
    final isCurrentRoute = location == NotificationManagementScreen.route;

    return AppIconButton(
      icon: icon,
      tooltip: unreadCount > 0 ? '$tooltip ($unreadCount unread)' : tooltip,
      variant: variant,
      size: size,
      foregroundColor: iconColor ?? context.colors.onSurfaceSecondary,
      isActive: isCurrentRoute,
      badge: unreadCount > 0
          ? AppBadge.count(
              unreadCount,
              color: badgeColor,
              foregroundColor: badgeTextColor,
            )
          : null,
      onPressed: onTap ??
          () {
            if (!isCurrentRoute) {
              context.go(NotificationManagementScreen.route);
            }
          },
    );
  }
}
