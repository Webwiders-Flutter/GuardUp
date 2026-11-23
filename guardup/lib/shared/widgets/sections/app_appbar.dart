import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/extensions/spacing.extension.dart';
import 'package:guardup/features/notifications/bloc/unread_count/unread_notification_count_cubit.dart';
import 'package:guardup/gen/assets.gen.dart';
import 'package:quick_container/quick_container.dart';

import '/core/extensions/context.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/back_button.dart';
import '/features/notifications/presentation/screens/notifications_screen.dart';

/// Alignment options for the app bar title text.
enum AlignTitle { left, right, center }

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

  final AlignTitle align;
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
    AlignTitle? alignTitle,
    this.automaticallyImplyLeading = false,
    this.height = kToolbarHeight,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
  }) : align = alignTitle ?? AlignTitle.right,
       _isTransparent = false;

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
    AlignTitle? alignTitle,
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
      alignTitle: alignTitle,
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
    AlignTitle? alignTitle,
    this.automaticallyImplyLeading = false,
    this.height = kToolbarHeight,
    this.foregroundColor,
    this.titleWidget,
  }) : align = alignTitle ?? AlignTitle.right,
       backgroundColor = null,
       elevation = 0,
       _isTransparent = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleNode =
        titleWidget ??
        (title != null
            ? Text(
                title!,
                style: (context.textTheme.titleLarge ?? const TextStyle())
                    .semiBold()
                    .copyWith(
                      fontSize: fontSize,
                      color:
                          foregroundColor ??
                          (theme.appBarTheme.foregroundColor ??
                              context.colors.onSurface),
                    ),
              )
            : null);

    return AppBar(
      toolbarHeight: height,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: align == AlignTitle.center,
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
        return shouldShowBack
            ? Row(
                children: [
                  context.horizontalScreenPadding.w,
                  BackIcon(onTap: onBackTap),
                ],
              )
            : null;
      }(),
      actions: [
        if (align == AlignTitle.right && titleNode != null)
          Padding(
            padding: context.horizontalEdgeInsets,
            child: Center(child: titleNode),
          ),
        ...?actions,
        if (showNotificationIcon)
          IconButton(
            onPressed:
                onNotificationTap ??
                () => context.go(NotificationsScreen.route),
            icon: QuickContainer(
              w: 40,
              h: 40,
              shape: QuickContainerShape.circle,
              color: context.colors.surfaceContainer,
              border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.7),
                width: 1,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Assets.svg.notificationBell.svg(
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      context.colors.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  BlocBuilder<UnreadNotificationCountCubit, int>(
                    bloc: sl.isRegistered<UnreadNotificationCountCubit>()
                        ? sl<UnreadNotificationCountCubit>()
                        : null,
                    builder: (context, unreadCount) {
                      if (unreadCount <= 0) return const SizedBox.shrink();
                      return Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.error,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: context.colors.surface,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
      bottom: bottom,
      title: align == AlignTitle.right ? null : titleNode,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
}
