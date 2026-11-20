import 'package:guardup_admin/core/constants/app_radius.dart';
import 'package:guardup_admin/core/constants/app_spacing.dart';
import 'package:guardup_admin/core/extensions/context.extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '../../di/notification.providers.dart';
import '/features/notifications/presentation/screens/notification_management.screen.dart';

/// A standard notification icon action widget (e.g. for app bars, navigation headers).
/// Automatically observes the live unread count and renders an indicator badge.
/// Tapping defaults to opening [NotificationManagementScreen.route] unless an explicit [onTap] is provided.
class NotificationIconWidget extends ConsumerWidget {
  /// Callback executed when the icon is pressed.
  /// Defaults to navigating to [NotificationManagementScreen.route].
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
    this.icon = Icons.notifications_active_outlined,
    this.iconColor,
    this.iconSize = 22,
    this.tooltip = 'Notifications',
    this.count,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount =
        count ??
        (ref.watch(unreadNotificationCountControllerProvider).value ?? 0);

    final button = IconButton(
      padding: EdgeInsets.zero,
      visualDensity: .compact,
      icon: QuickContainer(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderColor: context.colors.borderLight.withValues(alpha: 0.8),
        p: AppSpacing.xs + 1.5,
        child: Icon(
          icon,
          color: iconColor ?? context.colors.onSurface.withValues(alpha: 0.7),
          size: iconSize,
        ),
      ),
      onPressed:
          onTap ?? () => context.push(NotificationManagementScreen.route),
      tooltip: tooltip,
    );

    if (unreadCount > 0) {
      return Badge.count(
        count: unreadCount,
        backgroundColor: badgeColor ?? context.colors.error,
        textColor: badgeTextColor ?? context.colors.white,
        maxCount: 99,
        alignment: .topRight,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: button,
      );
    }

    return button;
  }
}
