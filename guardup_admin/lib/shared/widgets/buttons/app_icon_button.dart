import 'package:flutter/material.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '../../../core/extensions/context.extension.dart';

/// Visual treatment of an [AppIconButton].
enum AppIconButtonVariant {
  /// No fill or border until hovered. For dense chrome (sidebar, menus).
  ghost,

  /// Surface fill with a hairline border. Default for toolbars.
  outlined,

  /// Muted fill, no border. For secondary actions inside cards.
  tonal,
}

enum AppIconButtonSize { small, medium }

typedef _IconButtonSizeSpec = ({double dimension, double iconSize});

/// Square icon-only button used across the admin chrome: top bar actions,
/// table toolbars, sidebar toggles and pagination.
///
/// Supports a tooltip, an [isActive] toggle state, a loading spinner and an
/// optional [badge] (e.g. `AppBadge.count(3)`) pinned to the top-right corner.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.outlined,
    this.size = AppIconButtonSize.medium,
    this.isActive = false,
    this.isLoading = false,
    this.activeColor,
    this.foregroundColor,
    this.backgroundColor,
    this.badge,
  });

  final IconData icon;

  /// Null renders the button disabled.
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonVariant variant;
  final AppIconButtonSize size;

  /// Toggle state (e.g. selection mode on). Tints the button with
  /// [activeColor].
  final bool isActive;
  final bool isLoading;
  final Color? activeColor;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Widget? badge;

  static const Map<AppIconButtonSize, _IconButtonSizeSpec> _sizeSpecs = {
    AppIconButtonSize.small: (
      dimension: AppLayout.controlHeightSm,
      iconSize: AppLayout.iconSm,
    ),
    AppIconButtonSize.medium: (
      dimension: AppLayout.controlHeight,
      iconSize: AppLayout.iconMd,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spec = _sizeSpecs[size]!;
    final accent = activeColor ?? colors.primary;
    final enabled = onPressed != null && !isLoading;

    final Color fill;
    final Color? borderColor;
    if (isActive) {
      fill = accent.withValues(alpha: 0.12);
      borderColor = accent.withValues(alpha: 0.4);
    } else {
      fill =
          backgroundColor ??
          switch (variant) {
            AppIconButtonVariant.ghost => colors.transparent,
            AppIconButtonVariant.outlined => colors.surface,
            AppIconButtonVariant.tonal => colors.surfaceMuted,
          };
      borderColor = variant == AppIconButtonVariant.outlined
          ? colors.borderLight
          : null;
    }

    final iconColor = isActive
        ? accent
        : (foregroundColor ?? colors.onSurface).withValues(
            alpha: enabled ? 1 : 0.4,
          );

    Widget button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: AppRadius.mdRadius,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: AppDurations.instant,
          width: spec.dimension,
          height: spec.dimension,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.mdRadius,
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
          child: isLoading
              ? SizedBox.square(
                  dimension: spec.iconSize - 2,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accent,
                  ),
                )
              : Icon(icon, size: spec.iconSize, color: iconColor),
        ),
      ),
    );

    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(top: -4, right: -4, child: IgnorePointer(child: badge)),
        ],
      );
    }

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
