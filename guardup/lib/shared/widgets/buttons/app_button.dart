import 'package:flutter/material.dart';

import '/core/constants/app_sizes.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';

enum ButtonType {
  primary,
  secondaryPrimary,
  secondaryOff,
  text,
  success,
  warning,
  info,
  danger,
}

enum ButtonSize { small, normal, medium, large }

/// Resolved visual style specification for a [ButtonType].
/// Uses a record typedef to avoid unnecessary class boilerplate.
typedef _ButtonStyleSpec = ({
  Color background,
  Color foreground,
  BorderSide? border,
  double? elevation,
});

/// Resolved layout specification for a [ButtonSize].
/// Uses a record typedef to avoid unnecessary class boilerplate.
typedef _ButtonSizeSpec = ({
  double height,
  EdgeInsets padding,
  double fontSize,
});

/// Standardized enterprise button widget with consistent typography,
/// responsive sizing, loading states, and standard Flutter style overrides.
class AppButton extends StatelessWidget {
  /// Button label or icon (at least one must be provided)
  final String? text;
  final IconData? icon;

  /// Trigger callback
  final VoidCallback? onPressed;

  /// Variant and size configuration
  final ButtonType type;
  final ButtonSize size;
  final bool isFlexible;

  /// States
  final bool isLoading;
  final bool enabled;

  /// Optional prefix & suffix widgets
  final Widget? leading;
  final Widget? trailing;

  /// ── Standard Style Overrides ──────────────────────────────────────────────
  /// Standard Flutter types for comprehensive, consistent customization
  /// without fragmented micro-properties (e.g. leftPadding, verticalMargin).
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? splashColor;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final double? elevation;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  /// When true, renders a primary-colored ambient glow box shadow and border.
  final bool makeItGlow;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.type = .primary,
    this.size = .medium,
    this.isLoading = false,
    this.enabled = true,
    this.isFlexible = false,
    this.makeItGlow = false,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.foregroundColor,
    this.splashColor,
    this.border,
    this.borderRadius,
    this.elevation,
    this.textStyle,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.gradient,
    this.boxShadow,
  }) : assert(
         text != null || icon != null,
         'Either text or icon must be provided',
       ),
       assert(
         text == null || icon == null,
         'Only one of text or icon can be provided',
       );

  bool get _isEnabled => enabled && !isLoading && onPressed != null;

  // ---------------------------------------------------------------------
  // Size config — add a new ButtonSize by adding ONE entry here.
  // ---------------------------------------------------------------------
  static final Map<ButtonSize, _ButtonSizeSpec> _sizeSpecs = {
    ButtonSize.small: (
      height: AppSizes.buttonSm,
      padding: AppSpacing.md.xPadding,
      fontSize: 12,
    ),
    ButtonSize.normal: (
      height: AppSizes.buttonNormal,
      padding: AppSpacing.lg.xPadding,
      fontSize: 14,
    ),
    ButtonSize.medium: (
      height: AppSizes.buttonMd,
      padding: AppSpacing.lg.xPadding,
      fontSize: 15,
    ),
    ButtonSize.large: (
      height: AppSizes.buttonLg,
      padding: AppSpacing.xl.xPadding,
      fontSize: 17,
    ),
  };

  // ---------------------------------------------------------------------
  // Type config — add a new ButtonType by adding ONE entry here.
  // Built lazily since it needs `context.colors`.
  // ---------------------------------------------------------------------
  Map<ButtonType, _ButtonStyleSpec> _styleSpecs(BuildContext context) {
    final colors = context.colors;
    return {
      ButtonType.primary: (
        background: colors.primary,
        foreground: colors.onPrimary,
        border: null,
        elevation: null,
      ),
      ButtonType.secondaryPrimary: (
        background: colors.surface,
        foreground: colors.primary,
        border: BorderSide(color: colors.primary),
        elevation: 0,
      ),
      ButtonType.secondaryOff: (
        background: colors.surface,
        foreground: colors.onSurfaceVariant,
        border: BorderSide.none,
        elevation: 0,
      ),
      ButtonType.text: (
        background: colors.transparent,
        foreground: colors.primary,
        border: null,
        elevation: 0,
      ),
      ButtonType.success: (
        background: colors.success,
        foreground: colors.surface,
        border: null,
        elevation: null,
      ),
      ButtonType.warning: (
        background: colors.warning,
        foreground: colors.surface,
        border: null,
        elevation: null,
      ),
      ButtonType.info: (
        background: colors.info,
        foreground: colors.surface,
        border: null,
        elevation: null,
      ),
      ButtonType.danger: (
        background: colors.error,
        foreground: colors.surface,
        border: null,
        elevation: null,
      ),
    };
  }

  /// Resolves the final style, applying the disabled override in one
  /// place rather than inside every switch arm.
  _ButtonStyleSpec _resolveStyle(BuildContext context) {
    if (!_isEnabled) {
      if (type == ButtonType.text) {
        return (
          background: context.colors.transparent,
          foreground: context.colors.outline,
          border: null,
          elevation: 0,
        );
      }
      return (
        background: context.colors.outlineVariant,
        foreground: context.colors.onSurfaceVariant,
        border: BorderSide(color: context.colors.outlineVariant),
        elevation: 0,
      );
    }
    return _styleSpecs(context)[type]!;
  }

  TextStyle _resolveTextStyle(
    BuildContext context,
    Color foreground,
    _ButtonSizeSpec sizeSpec,
  ) {
    if (textStyle != null) {
      return textStyle!.colour(foreground);
    }

    final themeStyle =
        context.textTheme.labelLarge ??
        context.textTheme.bodyMedium ??
        ThemeData.fallback().textTheme.labelLarge!;
    final FontWeight resolvedWeight = switch (type) {
      ButtonType.text => FontWeight.w400,
      ButtonType.primary => FontWeight.w700,
      _ => FontWeight.w600,
    };

    return themeStyle
        .colour(foreground)
        .size(sizeSpec.fontSize)
        .weight(resolvedWeight);
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = Theme.of(context).elevatedButtonTheme.style;
    final style = _resolveStyle(context);
    final sizeSpec = _sizeSpecs[size]!;

    final resolvedBorder = border ?? style.border;
    final resolvedForeground = foregroundColor ?? style.foreground;
    final splashBaseColor = splashColor ?? resolvedForeground;
    final resolvedRadius = borderRadius ?? BorderRadius.circular(AppRadius.md);
    final resolvedBoxShadow =
        boxShadow ??
        (makeItGlow
            ? [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ]
            : null);

    final bool hasPrimaryGradient =
        type == ButtonType.primary && backgroundColor == null && _isEnabled;
    final effectiveGradient =
        gradient ??
        (hasPrimaryGradient ? context.colors.primaryGradient : null);

    final bool effectiveIsFlexible =
        isFlexible || type == ButtonType.text || width != null;
    final resolvedPadding =
        padding ??
        (type == ButtonType.text
            ? const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              )
            : sizeSpec.padding);
    final resolvedWidth =
        width ?? (effectiveIsFlexible ? null : double.infinity);
    final resolvedHeight =
        height ?? (type == ButtonType.text ? null : sizeSpec.height);

    Widget button = SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: resolvedRadius,
          border: resolvedBorder != null
              ? Border.fromBorderSide(resolvedBorder)
              : null,
          boxShadow: resolvedBoxShadow,
        ),
        child: ElevatedButton(
          onPressed: _isEnabled ? onPressed : null,
          style: (themeStyle ?? const ButtonStyle()).copyWith(
            backgroundColor: WidgetStatePropertyAll(
              effectiveGradient != null
                  ? context.colors.transparent
                  : (backgroundColor ?? style.background),
            ),
            foregroundColor: WidgetStatePropertyAll(resolvedForeground),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.pressed)) {
                return splashBaseColor.withValues(alpha: 0.22);
              }
              if (states.contains(WidgetState.hovered)) {
                return splashBaseColor.withValues(alpha: 0.10);
              }
              if (states.contains(WidgetState.focused)) {
                return splashBaseColor.withValues(alpha: 0.14);
              }
              return null;
            }),
            splashFactory: InkRipple.splashFactory,
            elevation: WidgetStatePropertyAll(
              effectiveGradient != null || type == ButtonType.text
                  ? 0.0
                  : (elevation ?? style.elevation),
            ),
            shadowColor: type == ButtonType.text
                ? const WidgetStatePropertyAll(Colors.transparent)
                : null,
            padding: WidgetStatePropertyAll(resolvedPadding),
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: resolvedBorder != null && effectiveGradient == null
                ? WidgetStatePropertyAll(resolvedBorder)
                : null,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: resolvedRadius),
            ),
          ),
          child: _buildChild(context, resolvedForeground, sizeSpec),
        ),
      ),
    );

    if (margin != null) {
      button = Padding(padding: margin!, child: button);
    }

    return button;
  }

  Widget _buildChild(
    BuildContext context,
    Color foreground,
    _ButtonSizeSpec sizeSpec,
  ) {
    if (isLoading) {
      return SizedBox(
        height: AppSizes.progressMd,
        width: AppSizes.progressMd,
        child: CircularProgressIndicator(
          strokeWidth: AppSpacing.xxs,
          valueColor: AlwaysStoppedAnimation(foreground),
        ),
      );
    }

    final mainWidget = text != null
        ? Text(
            text!,
            style: _resolveTextStyle(context, foreground, sizeSpec),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : Icon(icon, color: foreground, size: AppSizes.iconMd);

    if (leading == null && trailing == null) return mainWidget;

    return IconTheme.merge(
      data: IconThemeData(color: foreground, size: sizeSpec.fontSize + 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, AppSpacing.sm.w],
          Flexible(child: mainWidget),
          if (trailing != null) ...[AppSpacing.sm.w, trailing!],
        ],
      ),
    );
  }
}
