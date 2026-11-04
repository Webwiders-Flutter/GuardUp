import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/sections/app_image.dart';

/// A sleek, luxury gold pill chip with an integrated remove ("X") button,
/// matching GuardUp dark luxury design standards.
///
/// Typically used for active tags, selected filters, categories, or assigned entities.
class AppRemovableChip extends StatelessWidget {
  /// The label text displayed on the chip.
  final String text;

  /// Callback executed when the remove button is tapped.
  final VoidCallback? onRemove;

  /// Optional callback executed when the chip body itself is tapped.
  final VoidCallback? onTap;

  /// Optional leading [IconData].
  final IconData? icon;

  /// Optional asset path for a leading icon (SVG or raster).
  final String? iconAssetPath;

  /// Custom leading widget overriding [icon] and [iconAssetPath].
  final Widget? leading;

  /// Custom trailing widget overriding the default remove ("X") icon button.
  final Widget? trailing;

  /// Custom remove icon data. Defaults to [Icons.close_rounded].
  final IconData removeIcon;

  /// Custom size for the remove icon. Defaults to 16.0.
  final double removeIconSize;

  /// Custom gradient for the chip background. Defaults to [context.colors.primaryGradient].
  final Gradient? gradient;

  /// Solid background color used when [gradient] is null or overridden.
  final Color? backgroundColor;

  /// Foreground color for text and icons. Defaults to [context.colors.onPrimary].
  final Color? foregroundColor;

  /// Optional border around the chip.
  final BoxBorder? border;

  /// Corner radius. Defaults to [AppRadius.round] (28.0).
  final double? radius;

  /// Height of the chip. Defaults to null (shrink-wraps based on padding).
  final double? height;

  /// Width of the chip. Defaults to null (shrink-wraps horizontally).
  final double? width;

  /// Horizontal padding inside the chip. Defaults to [AppSpacing.md] (16.0).
  final double? px;

  /// Vertical padding inside the chip. Defaults to [AppSpacing.xs] (8.0).
  final double? py;

  /// Text style override for the label.
  final TextStyle? textStyle;

  /// Whether the chip is enabled for interaction. Defaults to `true`.
  final bool enabled;

  /// Optional tooltip message for the remove button.
  final String? removeTooltip;

  /// Alignment of content inside the chip container.
  /// Defaults to null to allow natural shrink-wrapping inside [Wrap] or row layouts.
  final AlignmentGeometry? alignment;

  const AppRemovableChip({
    super.key,
    required this.text,
    this.onRemove,
    this.onTap,
    this.icon,
    this.iconAssetPath,
    this.leading,
    this.trailing,
    this.removeIcon = Icons.close_rounded,
    this.removeIconSize = 16.0,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
    this.radius,
    this.height,
    this.width,
    this.px,
    this.py,
    this.textStyle,
    this.enabled = true,
    this.removeTooltip,
    this.alignment,
  });

  /// Alias for [text].
  String get label => text;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = radius ?? AppRadius.sm;
    final effectiveForeground = foregroundColor ?? context.colors.onPrimary;
    final effectiveGradient = backgroundColor != null
        ? null
        : (gradient ?? context.colors.primaryGradient);

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && iconAssetPath != null) {
      effectiveLeading = AppImage.asset(
        assetPath: iconAssetPath!,
        width: 16,
        height: 16,
        color: effectiveForeground,
      );
    } else if (effectiveLeading == null && icon != null) {
      effectiveLeading = Icon(icon, size: 16, color: effectiveForeground);
    }

    final Widget effectiveTrailing =
        trailing ?? _buildRemoveButton(context, effectiveForeground);

    return QuickContainer(
      w: width,
      h: height,
      px: px ?? AppSpacing.md,
      py: py ?? AppSpacing.ssm,
      radius: effectiveRadius,
      gradient: effectiveGradient,
      color: backgroundColor,
      border: border,
      onTap: enabled ? onTap : null,
      ripple: enabled && onTap != null,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (effectiveLeading != null) ...[effectiveLeading, AppSpacing.xs.w],
          Flexible(
            child: Text(
              text,
              style: (textStyle ?? context.textTheme.labelLarge)
                  ?.decreaseSize(1)
                  .bold()
                  .colour(effectiveForeground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.sm.w,
          effectiveTrailing,
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context, Color color) {
    final Widget button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onRemove : null,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Icon(removeIcon, size: removeIconSize, color: color),
      ),
    );

    if (removeTooltip != null && removeTooltip!.isNotEmpty) {
      return Tooltip(message: removeTooltip!, child: button);
    }

    return button;
  }
}
