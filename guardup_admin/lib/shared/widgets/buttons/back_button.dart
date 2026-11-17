import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';

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
    this.size = AppSpacing.xxxl,
    this.iconSize = AppSpacing.xl,
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
    final colors = context.colors;
    final effectiveBg = backgroundColor ?? colors.surface;
    final effectiveIconColor = iconColor ?? colors.primary;

    return Center(
      child: Tooltip(
        message: fallbackRoute ?? 'Back',
        child: Material(
          color: effectiveBg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _handleTap(context),
            customBorder: const CircleBorder(),
            hoverColor: effectiveIconColor.withValues(alpha: 0.08),
            splashColor: effectiveIconColor.withValues(alpha: 0.14),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderLight, width: 1),
              ),
              child: Icon(icon, color: effectiveIconColor, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
