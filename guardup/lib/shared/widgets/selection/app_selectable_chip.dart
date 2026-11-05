import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/sections/app_image.dart';
import 'selection.controller.dart';

/// A compact, luxury-styled selectable chip/segment widget powered by [SelectionController].
///
/// Features the signature gold primary gradient when selected and a sleek dark container
/// when unselected, matching GuardUp design standards.
class AppSelectableChip<T> extends StatelessWidget {
  /// The [SelectionController] driving this chip's selection state.
  final SelectionController<T> controller;

  /// The unique value associated with this chip.
  final T value;

  /// Label text displayed on the chip.
  final String label;

  /// Optional leading [IconData].
  final IconData? icon;

  /// Optional asset path for a leading icon (SVG or raster).
  final String? iconAssetPath;

  /// Custom leading widget overriding [icon] and [iconAssetPath].
  final Widget? leading;

  /// Height of the chip. Defaults to 48.0.
  final double? height;

  /// Width of the chip. If null, sizes flexibly.
  final double? width;

  /// Padding inside the chip. Defaults to horizontal: `AppSpacing.xs`, vertical: `AppSpacing.sm`.
  final double? px;
  final double? py;

  /// Corner radius. Defaults to `AppRadius.md`.
  final double? radius;

  /// Optional tap callback executed alongside selection toggle.
  final VoidCallback? onTap;

  /// Whether the chip is enabled for interaction.
  final bool enabled;

  const AppSelectableChip({
    super.key,
    required this.controller,
    required this.value,
    required this.label,
    this.icon,
    this.iconAssetPath,
    this.leading,
    this.height = 48.0,
    this.width,
    this.px,
    this.py,
    this.radius,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: controller,
      builder: (context, selection, _) {
        final isSelected = selection.contains(value);
        final effectiveRadius = radius ?? AppRadius.md;

        final foregroundColor = isSelected
            ? context.colors.onPrimary
            : context.colors.onSurfaceVariant;

        Widget? effectiveLeading = leading;
        if (effectiveLeading == null && iconAssetPath != null) {
          effectiveLeading = AppImage.asset(
            assetPath: iconAssetPath!,
            width: 18,
            height: 18,
            color: foregroundColor,
          );
        } else if (effectiveLeading == null && icon != null) {
          effectiveLeading = Icon(icon, size: 20, color: foregroundColor);
        }

        return QuickContainer(
          w: width,
          h: height,
          px: px ?? AppSpacing.xs,
          py: py ?? AppSpacing.sm,
          radius: effectiveRadius,
          gradient: isSelected ? context.colors.primaryGradient : null,
          color: isSelected
              ? null
              : context.colors.surfaceContainer.withValues(alpha: 0.72),
          border: isSelected
              ? null
              : Border.all(color: context.colors.outlineVariant, width: 1),
          onTap: enabled
              ? () {
                  controller.toggle(value);
                  onTap?.call();
                }
              : null,
          ripple: enabled,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (effectiveLeading != null) ...[
                effectiveLeading,
                AppSpacing.sm.w,
              ],
              Flexible(
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium
                      ?.weight(isSelected ? FontWeight.w700 : FontWeight.w600)
                      .colour(foregroundColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
