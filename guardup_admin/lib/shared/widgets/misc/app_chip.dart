import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Available sizes for [AppChip] aligned with enterprise button/table ergonomics.
enum AppChipSize { small, normal, medium, large }

/// Internal layout specification for a [AppChipSize].
/// Uses a record typedef to comply with rules.md Section 13.
typedef _ChipSizeSpec = ({
  EdgeInsets padding,
  double fontSize,
  double defaultIconSize,
  double gap,
});

/// Standardized enterprise status pill / badge widget.
///
/// Fully adheres to rules.md (§2A, §2B, §2C, §13, §15):
/// - Accepts [color] which automatically drives border, foreground, and tinted background.
/// - Capsule stadium ends ([AppRadius.fullRadius]) by default, customizable via [borderRadius].
/// - Optional [icon], [iconSize], [titleStyle], [onTap], and [size] configurations.
/// - Clean, uncluttered API without fragmented micro-properties.
class AppChip extends StatelessWidget {
  /// The semantic/theme color used for foreground, border, and background tint.
  final Color color;

  /// The text label displayed inside the chip.
  final String title;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional icon size override. When null, resolves to the size's default.
  final double? iconSize;

  /// Optional typography style override for [title].
  final TextStyle? titleStyle;

  /// Optional border radius. Defaults to [AppRadius.fullRadius].
  final BorderRadius? borderRadius;

  /// Optional tap callback. When provided, renders with a click cursor and ink ripple.
  final VoidCallback? onTap;

  /// Sizing scale for padding, font size, and default icon size.
  final AppChipSize size;

  const AppChip({
    super.key,
    required this.color,
    required this.title,
    this.icon,
    this.iconSize,
    this.titleStyle,
    this.borderRadius,
    this.onTap,
    this.size = AppChipSize.normal,
  });

  // ---------------------------------------------------------------------
  // Size specifications mapping
  // ---------------------------------------------------------------------
  static const Map<AppChipSize, _ChipSizeSpec> _sizeSpecs = {
    AppChipSize.small: (
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm, // 8.0
        vertical: 2.0,
      ),
      fontSize: AppSpacing.md - 2, // 10.0
      defaultIconSize: AppSpacing.md, // 12.0
      gap: (AppSpacing.xs / 2) + 1, // 3.0
    ),
    AppChipSize.normal: (
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2, // 10.0
        vertical: (AppSpacing.xs / 2) + 1, // 3.0
      ),
      fontSize: AppSpacing.md - 1, // 11.0
      defaultIconSize: AppSpacing.md + 1, // 13.0
      gap: AppSpacing.xs, // 4.0
    ),
    AppChipSize.medium: (
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md, // 12.0
        vertical: AppSpacing.xs, // 4.0
      ),
      fontSize: AppSpacing.md, // 12.0
      defaultIconSize: AppSpacing.md + 2, // 14.0
      gap: AppSpacing.xs + 1, // 5.0
    ),
    AppChipSize.large: (
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg - 2, // 14.0
        vertical: AppSpacing.xs + 1.5, // 5.5
      ),
      fontSize: AppSpacing.md + 1, // 13.0
      defaultIconSize: AppSpacing.lg, // 16.0
      gap: AppSpacing.sm, // 8.0
    ),
  };

  @override
  Widget build(BuildContext context) {
    final spec = _sizeSpecs[size]!;
    final effectiveRadius = borderRadius ?? AppRadius.fullRadius;
    final effectiveIconSize = iconSize ?? spec.defaultIconSize;

    final resolvedTextStyle =
        titleStyle ??
        context.textTheme.labelSmall
            ?.semiBold()
            .size(spec.fontSize)
            .colour(color);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: effectiveIconSize, color: color),
          spec.gap.w,
        ],
        Flexible(
          child: Text(
            title,
            style: resolvedTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color.withValues(alpha: isDark ? 0.16 : 0.08);
    final borderColor = color.withValues(alpha: isDark ? 0.35 : 0.25);

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: effectiveRadius,
            border: Border.all(color: borderColor),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveRadius,
            hoverColor: color.withValues(alpha: isDark ? 0.12 : 0.06),
            splashColor: color.withValues(alpha: isDark ? 0.20 : 0.12),
            child: Padding(padding: spec.padding, child: content),
          ),
        ),
      );
    }

    return Container(
      padding: spec.padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveRadius,
        border: Border.all(color: borderColor),
      ),
      child: content,
    );
  }
}

/// Convenience alias for [AppChip].
typedef AppBadge = AppChip;
