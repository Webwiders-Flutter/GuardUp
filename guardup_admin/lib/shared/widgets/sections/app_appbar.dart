import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/logger/app_logger.dart';
import '/shared/widgets/buttons/back_button.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;

  final Widget? leading;
  final double? leadingWidth;
  final bool? showBackIcon;
  final Widget? notificationOverride;
  final bool showNotificationIcon;

  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  final bool centerTitle;
  final bool automaticallyImplyLeading;

  final double height;
  final double elevation;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isTransparent;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.bottom,
    this.leadingWidth,
    this.showBackIcon,
    this.notificationOverride,
    this.showNotificationIcon = false,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
    this.height = kToolbarHeight,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.isTransparent = false,
  });

  factory AppAppBar.primary({
    required String title,
    Widget? leading,
    List<Widget>? actions,
    double? leadingWidth,
    bool? showBackIcon,
    bool showNotificationIcon = false,
    int notificationCount = 0,
    VoidCallback? onNotificationTap,
    IconData notificationIcon = Icons.notifications_outlined,
    Color? notificationIconColor,
  }) {
    return AppAppBar(
      title: title,
      leading: leading,
      actions: actions,
      showBackIcon: showBackIcon,
      leadingWidth: leadingWidth,
      showNotificationIcon: showNotificationIcon,
    );
  }

  const AppAppBar.transparent({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.notificationOverride,
    this.bottom,
    this.showBackIcon = true,
    this.elevation = 0,
    this.leadingWidth,
    this.showNotificationIcon = false,
    this.centerTitle = true,
    this.automaticallyImplyLeading = false,
    this.height = kToolbarHeight,
    this.foregroundColor,
    this.titleWidget,
  }) : backgroundColor = null,
       isTransparent = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: height,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: isTransparent
          ? context.colors.transparent
          : (backgroundColor ?? theme.appBarTheme.backgroundColor),
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      leadingWidth: leadingWidth,
      leading: () {
        bool canPop;
        try {
          canPop = context.canPop();
        } catch (e, st) {
          AppLogger.e('Failed to check canPop', error: e, stackTrace: st);
          canPop = false;
        }
        final shouldShowBack = showBackIcon ?? canPop;

        if (leading != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [if (shouldShowBack) const BackIcon(), leading!],
          );
        }
        return shouldShowBack ? const BackIcon() : null;
      }(),
      actions: [
        ...?actions,
        if (showNotificationIcon)
          notificationOverride ?? _buildNotificationAction(theme.colorScheme),
      ],
      bottom: bottom,
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: context.textTheme.titleMedium?.colour(
                    foregroundColor ??
                        theme.appBarTheme.foregroundColor ??
                        context.colors.onSurface,
                  ),
                )
              : null),
    );
  }

  Widget _buildNotificationAction(ColorScheme colors) {
    final button = IconButton(
      icon: Icon(
        Icons.notifications_outlined,
        color: foregroundColor,
        size: 24,
      ),
      onPressed: () {},
      tooltip: 'Notifications',
    );

    if (3 > 0) {
      return Badge.count(count: 3, child: button);
    }

    return button;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
}
