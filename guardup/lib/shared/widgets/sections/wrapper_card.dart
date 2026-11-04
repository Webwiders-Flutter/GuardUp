import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';

/// Reusable section wrapper card with standardized styling, optional header, action, borders, and shadows.
class WrapperCard extends StatelessWidget {
  /// The main content inside the card.
  final Widget child;

  /// Optional plain-text title rendered in the card header.
  final String? title;

  /// Optional custom title widget override.
  final Widget? titleWidget;

  /// Optional SVG icon for the header.
  final SvgGenImage? svg;

  /// Optional material icon data for the header.
  final IconData? iconData;

  /// Optional custom icon widget override.
  final Widget? icon;

  /// Optional custom action widget on the top-right.
  final Widget? action;

  /// Optional text label for default text action button.
  final String? actionLabel;

  /// Callback when header action is tapped.
  final VoidCallback? onActionTap;

  /// Optional icon placed beside [actionLabel].
  final IconData? actionIcon;

  /// Whether to display a red asterisk after the title.
  final bool isRequired;

  /// Inner padding of the card container.
  final EdgeInsetsGeometry? padding;

  /// Vertical spacing between header and [child].
  final double? headerSpacing;

  /// Icon size/height if [svg] or [iconData] is provided.
  final double? iconHeight;

  /// Background color of the card. Defaults to [AppColors.surfaceContainer].
  final Color? backgroundColor;

  /// Border color of the card. Defaults to [AppColors.outlineVariant].
  final Color? borderColor;

  /// Border thickness. Defaults to 1.0.
  final double? borderWidth;

  /// Custom border override. If provided, overrides [borderColor] and [borderWidth].
  final BoxBorder? border;

  /// Optional background gradient override.
  final Gradient? gradient;

  /// Corner radius of the card. Defaults to [AppRadius.lg].
  final double? borderRadius;

  /// Background color behind header icon.
  final Color? iconBackgroundColor;

  /// Tint color for header icon.
  final Color? iconColor;

  /// Shadows or glow applied to the card.
  final List<BoxShadow>? shadows;

  /// Optional callback when the whole card is tapped.
  final VoidCallback? onTap;

  /// Whether to show a touch ripple when [onTap] is provided. Defaults to `true`.
  final bool ripple;

  /// External margin around the card container.
  final EdgeInsetsGeometry? margin;

  /// Card width. Defaults to `double.infinity`.
  final double? width;

  /// Card height. Defaults to auto.
  final double? height;

  /// Horizontal alignment of children in the card column.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether to render a horizontal divider below the header.
  final bool showHeaderDivider;

  /// Color of the divider line if [showHeaderDivider] is true.
  final Color? dividerColor;

  const WrapperCard({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.svg,
    this.iconData,
    this.icon,
    this.action,
    this.actionLabel,
    this.onActionTap,
    this.actionIcon,
    this.isRequired = false,
    this.padding,
    this.headerSpacing,
    this.iconHeight,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.border,
    this.gradient,
    this.borderRadius,
    this.iconBackgroundColor,
    this.iconColor,
    this.shadows,
    this.onTap,
    this.ripple = true,
    this.margin,
    this.width = double.infinity,
    this.height,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.showHeaderDivider = false,
    this.dividerColor,
  });

  Widget? _buildAction(BuildContext context) {
    if (action != null) return action;

    if (actionLabel != null || onActionTap != null) {
      final effectiveActionColor = context.colors.primary;
      return GestureDetector(
        onTap: onActionTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actionIcon != null) ...[
              Icon(actionIcon, size: 16, color: effectiveActionColor),
              AppSpacing.xs.w,
            ],
            if (actionLabel != null)
              Text(
                actionLabel!,
                style: context.textTheme.labelMedium?.semiBold().colour(
                  effectiveActionColor,
                ),
              ),
          ],
        ),
      );
    }
    return null;
  }

  Widget _buildTitle(BuildContext context) {
    if (titleWidget != null) return titleWidget!;

    if (title != null) {
      final labelStyle = context.textTheme.titleSmall?.semiBold().colour(
        context.colors.onSurface,
      );

      if (!isRequired) {
        return Text(title!, style: labelStyle);
      }

      return Text.rich(
        TextSpan(
          text: title,
          style: labelStyle,
          children: [
            TextSpan(
              text: ' *',
              style: labelStyle?.colour(context.colors.error),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget? _buildIconWidget(BuildContext context) {
    if (icon != null) return icon;
    if (svg != null) {
      return svg!.svg(
        width: iconHeight ?? 18,
        height: iconHeight ?? 18,
        colorFilter: ColorFilter.mode(
          iconColor ?? context.colors.primary,
          BlendMode.srcIn,
        ),
      );
    }
    if (iconData != null) {
      return Icon(
        iconData,
        size: iconHeight ?? 20,
        color: iconColor ?? context.colors.primary,
      );
    }
    return null;
  }

  Widget? _buildHeader(BuildContext context) {
    final iconWidget = _buildIconWidget(context);
    final actionWidget = _buildAction(context);
    final hasTitle = title != null || titleWidget != null;

    if (iconWidget == null && !hasTitle && actionWidget == null) {
      return null;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (iconWidget != null || hasTitle)
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconWidget != null) ...[
                  if (iconBackgroundColor != null)
                    QuickContainer(
                      p: AppSpacing.xs,
                      radius: AppRadius.sm,
                      color: iconBackgroundColor,
                      alignment: Alignment.center,
                      child: iconWidget,
                    )
                  else
                    iconWidget,
                  AppSpacing.sm.w,
                ],
                if (hasTitle) Expanded(child: _buildTitle(context)),
              ],
            ),
          )
        else
          const Spacer(),
        ?actionWidget,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor =
        backgroundColor ?? context.colors.surface.withValues(alpha: 0.9);
    final effectiveBorder = border ??
        Border.all(
          color: borderColor ?? context.colors.outlineVariant,
          width: borderWidth ?? 1.0,
        );
    final effectiveRadius = borderRadius ?? AppRadius.lg;
    final effectivePadding = padding ?? AppSpacing.lg.allPadding;
    final effectiveHeaderSpacing = headerSpacing ?? AppSpacing.md;

    final header = _buildHeader(context);

    final borderRad = BorderRadius.circular(effectiveRadius);

    Widget cardContent = Padding(
      padding: effectivePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (header != null) ...[
            header,
            if (showHeaderDivider) ...[
              effectiveHeaderSpacing.h,
              Container(
                height: 1,
                color:
                    dividerColor ??
                    context.colors.outline.withValues(alpha: 0.15),
              ),
            ],
            effectiveHeaderSpacing.h,
          ],
          child,
        ],
      ),
    );

    if (onTap != null) {
      cardContent = Material(
        color: context.colors.transparent,
        borderRadius: borderRad,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRad,
          splashColor: context.colors.primary.withValues(alpha: 0.08),
          highlightColor: context.colors.transparent,
          child: cardContent,
        ),
      );
    }

    final Widget card = QuickContainer(
      w: width,
      h: height,
      color: gradient != null ? null : effectiveBgColor,
      gradient: gradient,
      radius: effectiveRadius,
      p: 0,
      border: effectiveBorder,
      shadows: shadows,
      clipBehavior: Clip.antiAlias,
      child: cardContent,
    );

    if (margin != null) {
      return Padding(padding: margin!, child: card);
    }

    return card;
  }
}
