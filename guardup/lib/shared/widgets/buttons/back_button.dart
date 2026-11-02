import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/extensions/context.extension.dart';

class BackIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final bool closeKeyboardFirst;
  final Color? backgroundColor;
  final Color? iconColor;
  final IconData icon;
  final double size;
  final double iconSize;
  final String? fallbackRoute;

  const BackIcon({
    super.key,
    this.onTap,
    this.closeKeyboardFirst = true,
    this.backgroundColor,
    this.iconColor,
    this.icon = Icons.arrow_back,
    this.size = AppSizes.avatarSm,
    this.iconSize = AppSizes.iconMd,
    this.fallbackRoute,
  });

  void _handleTap(BuildContext context) {
    if (closeKeyboardFirst) {
      final currentFocus = FocusScope.of(context);
      final isKeyboardOpen =
          MediaQuery.viewInsetsOf(context).bottom > 0 ||
          currentFocus.focusedChild != null;

      if (isKeyboardOpen) {
        currentFocus.unfocus();
        return;
      }
    }

    if (onTap != null) {
      onTap!();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: fallbackRoute ?? 'Back',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _handleTap(context),
            behavior: HitTestBehavior.opaque,
            child: QuickContainer(
              w: size,
              h: size,
              shape: QuickContainerShape.circle,
              color: backgroundColor ?? context.colors.surface,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor ?? context.colors.primary,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
