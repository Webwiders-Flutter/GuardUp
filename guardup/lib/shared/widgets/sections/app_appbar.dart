import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/shared/widgets/buttons/back_button.dart';

import '../../../core/extensions/context.extension.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;

  final Widget? leading;
  final double? leadingWidth;
  final bool? showBackIcon;
  final VoidCallback? onBackTap;
  final bool showNotificationIcon;
  final VoidCallback? onNotificationTap;
  final IconData notificationIcon;
  final Color? notificationIconColor;

  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  final bool centerTitle;
  final bool automaticallyImplyLeading;

  final double height;
  final double elevation;
  final double? fontSize;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool _isTransparent;

  const AppAppBar({
    super.key,
    this.title,
    this.fontSize,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.leadingWidth,
    this.showBackIcon,
    this.onBackTap,
    this.showNotificationIcon = false,
    this.onNotificationTap,
    this.notificationIcon = Icons.notifications_outlined,
    this.notificationIconColor = Colors.white,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
    this.height = kToolbarHeight,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
  }) : _isTransparent = false;

  factory AppAppBar.primary({
    required String title,
    Widget? leading,
    List<Widget>? actions,
    double? leadingWidth,
    bool? showBackIcon,
    VoidCallback? onBackTap,
    bool showNotificationIcon = false,
    VoidCallback? onNotificationTap,
    IconData notificationIcon = Icons.notifications_outlined,
    Color? notificationIconColor = Colors.white,
  }) {
    return AppAppBar(
      title: title,
      leading: leading,
      actions: actions,
      showBackIcon: showBackIcon,
      onBackTap: onBackTap,
      leadingWidth: leadingWidth,
      showNotificationIcon: showNotificationIcon,
      onNotificationTap: onNotificationTap,
      notificationIcon: notificationIcon,
      notificationIconColor: notificationIconColor,
    );
  }

  const AppAppBar.transparent({
    super.key,
    this.title,
    this.actions,
    this.fontSize,
    this.leading,
    this.bottom,
    this.showBackIcon,
    this.onBackTap,
    this.leadingWidth,
    this.showNotificationIcon = false,
    this.onNotificationTap,
    this.notificationIcon = Icons.notifications_outlined,
    this.notificationIconColor = Colors.white,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
    this.height = kToolbarHeight,
    this.foregroundColor,
    this.titleWidget,
  }) : backgroundColor = null,
       elevation = 0,
       _isTransparent = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: height,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: _isTransparent
          ? context.colors.transparent
          : (backgroundColor ?? theme.appBarTheme.backgroundColor),
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      leadingWidth: leadingWidth,
      leading: () {
        bool canPop;
        try {
          canPop = context.canPop();
        } catch (_) {
          canPop = Navigator.of(context).canPop();
        }
        final shouldShowBack = showBackIcon ?? canPop;

        if (leading != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shouldShowBack) BackIcon(onTap: onBackTap),
              leading!,
            ],
          );
        }
        return shouldShowBack ? BackIcon(onTap: onBackTap) : null;
      }(),
      actions: [
        ...?actions,
        if (showNotificationIcon) Icon(Icons.notifications_active_outlined),
        // NotificationIconWidget(
        //   icon: notificationIcon,
        //   iconColor: notificationIconColor ?? theme.colorScheme.surface,
        //   onTap:
        //       onNotificationTap ??
        //       () {
        //         context.push(AppRoutes.notifications);
        //       },
        // ),
      ],
      bottom: bottom,
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontSize: fontSize,
                    color: foregroundColor ?? theme.appBarTheme.foregroundColor,
                  ),
                )
              : null),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
}
