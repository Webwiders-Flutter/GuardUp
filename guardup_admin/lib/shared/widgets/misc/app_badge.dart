import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_layout.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Compact pill badge for counts ("12", "99+"), short tags ("NEW", "LIVE")
/// and status dots. Used by sidebar items, icon buttons and menus.
///
/// The foreground defaults to a readable black/white picked from the
/// background's brightness, so any status color can be passed safely.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required String this.label,
    this.color,
    this.foregroundColor,
  }) : count = null,
       max = 0,
       isDot = false,
       ringColor = null;

  /// Numeric count badge, capped at [max] (renders "99+").
  const AppBadge.count(
    int this.count, {
    super.key,
    this.max = 99,
    this.color,
    this.foregroundColor,
  }) : label = null,
       isDot = false,
       ringColor = null;

  /// Small status dot. [ringColor] draws a separating ring (e.g. the surface
  /// color when the dot overlaps an avatar or icon).
  const AppBadge.dot({super.key, this.color, this.ringColor})
    : label = null,
      count = null,
      max = 0,
      foregroundColor = null,
      isDot = true;

  final String? label;
  final int? count;
  final int max;
  final Color? color;
  final Color? foregroundColor;
  final Color? ringColor;
  final bool isDot;

  static const double _dotSize = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final background = color ?? context.colors.error;

    if (isDot) {
      return QuickContainer(
        w: _dotSize,
        h: _dotSize,
        shape: QuickContainerShape.circle,
        color: background,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: AppSpacing.xs / 2)
            : null,
      );
    }

    final foreground =
        foregroundColor ??
        (ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? context.colors.white
            : context.colors.black);

    final text = count != null ? (count! > max ? '$max+' : '$count') : label!;

    return QuickContainer(
      minW: AppLayout.iconLg - AppSpacing.xs,
      px: AppSpacing.xs + 2,
      py: 1,
      shape: QuickContainerShape.stadium,
      alignment: Alignment.center,
      color: background,
      child: Text(
        text,
        maxLines: 1,
        style: context.textTheme.labelSmall
            ?.size(AppSpacing.sm + 2)
            .bold()
            .lineHeight(1.3)
            .colour(foreground),
      ),
    );
  }
}
