import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

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

  /// States
  final bool isLoading;
  final bool enabled;
  final bool fullWidth;

  /// Optional prefix & suffix widgets
  final Widget? leading;
  final Widget? trailing;

  /// ── Standard Style Overrides ──────────────────────────────────────────────
  /// Standard Flutter types for comprehensive, consistent customization
  /// without fragmented micro-properties (e.g. leftPadding, verticalMargin).
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final double? elevation;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.enabled = true,
    this.fullWidth = true,
    this.leading,
    this.trailing,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
    this.borderRadius,
    this.elevation,
    this.textStyle,
    this.padding,
    this.margin,
    this.width,
    this.height,
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
  static const Map<ButtonSize, _ButtonSizeSpec> _sizeSpecs = {
    ButtonSize.small: (
      height: AppRadius.round,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
      fontSize: AppSpacing.md - 1,
    ),
    ButtonSize.normal: (
      height: AppSpacing.md * 3,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
      fontSize: AppSpacing.md + 1,
    ),
    ButtonSize.medium: (
      height: (AppSpacing.md * 3) + 2,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      fontSize: AppSpacing.md + 2,
    ),
    ButtonSize.large: (
      height: AppSpacing.xxl + AppSpacing.xl,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      fontSize: AppSpacing.lg - 1,
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
        foreground: colors.onSurfaceSecondary,
        border: BorderSide(color: colors.onSurfaceSecondary),
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
      return (
        background: context.colors.borderLight,
        foreground: context.colors.onSurfaceSecondary,
        border: BorderSide(color: context.colors.onSurfaceSecondary),
        elevation: 0,
      );
    }
    return _styleSpecs(context)[type] ??
        _styleSpecs(context)[ButtonType.primary]!;
  }

  _ButtonSizeSpec _resolveSize() =>
      _sizeSpecs[size] ?? _sizeSpecs[ButtonSize.medium]!;

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
    return themeStyle
        .colour(foreground)
        .size(sizeSpec.fontSize)
        .weight(FontWeight.w600);
  }

  @override
  Widget build(BuildContext context) {
    final themeStyle = Theme.of(context).elevatedButtonTheme.style;
    final style = _resolveStyle(context);
    final sizeSpec = _resolveSize();

    final resolvedBackground = backgroundColor ?? style.background;
    final resolvedForeground = foregroundColor ?? style.foreground;
    final resolvedBorder = border ?? style.border;
    final resolvedElevation = elevation ?? style.elevation;
    final resolvedHeight = height ?? sizeSpec.height;
    final resolvedPadding = padding ?? sizeSpec.padding;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canBeFullWidth = fullWidth && constraints.hasBoundedWidth;
        final resolvedWidth = width ?? (canBeFullWidth ? double.infinity : null);

        Widget button = SizedBox(
          width: resolvedWidth,
          height: resolvedHeight,
          child: ElevatedButton(
            onPressed: _isEnabled ? onPressed : null,
            style: (themeStyle ?? const ButtonStyle()).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (!_isEnabled) return context.colors.borderLight;
                return resolvedBackground;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (!_isEnabled) return context.colors.onSurfaceSecondary;
                return resolvedForeground;
              }),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (!_isEnabled) return null;
                if (states.contains(WidgetState.pressed)) {
                  return resolvedForeground.withValues(alpha: 0.14);
                }
                if (states.contains(WidgetState.hovered)) {
                  return resolvedForeground.withValues(alpha: 0.08);
                }
                if (states.contains(WidgetState.focused)) {
                  return resolvedForeground.withValues(alpha: 0.12);
                }
                return null;
              }),
              elevation: WidgetStateProperty.resolveWith((states) {
                final baseElevation = resolvedElevation ?? 0.0;
                if (!_isEnabled) return 0.0;
                if (states.contains(WidgetState.pressed)) {
                  return baseElevation > 0 ? baseElevation - 1.0 : 0.0;
                }
                if (states.contains(WidgetState.hovered) && baseElevation > 0) {
                  return baseElevation + 1.5;
                }
                return baseElevation;
              }),
              mouseCursor: WidgetStateProperty.resolveWith((states) {
                return _isEnabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic;
              }),
              padding: WidgetStatePropertyAll(resolvedPadding),
              side: resolvedBorder != null
                  ? WidgetStatePropertyAll(resolvedBorder)
                  : null,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius:
                      borderRadius ??
                      (size == ButtonSize.small
                          ? AppRadius.smRadius
                          : AppRadius.mdRadius),
                ),
              ),
            ),
            child: _buildChild(context, resolvedForeground, sizeSpec),
          ),
        );

        if (margin != null) {
          button = Padding(padding: margin!, child: button);
        }

        return button;
      },
    );
  }

  Widget _buildChild(
    BuildContext context,
    Color foreground,
    _ButtonSizeSpec sizeSpec,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: isLoading
          ? SizedBox(
              key: const ValueKey('button_loading'),
              height: AppSpacing.lg + 2,
              width: AppSpacing.lg + 2,
              child: CircularProgressIndicator(
                strokeWidth: AppSpacing.xs / 2,
                valueColor: AlwaysStoppedAnimation(foreground),
              ),
            )
          : KeyedSubtree(
              key: const ValueKey('button_content'),
              child: _buildContent(context, foreground, sizeSpec),
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color foreground,
    _ButtonSizeSpec sizeSpec,
  ) {
    final mainWidget = text != null
        ? Text(
            text!,
            style: _resolveTextStyle(context, foreground, sizeSpec),
            textAlign: TextAlign.center,
          )
        : Icon(icon, color: foreground, size: AppSpacing.xl);

    if (leading == null && trailing == null) return mainWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, AppSpacing.sm.w],
        mainWidget,
        if (trailing != null) ...[AppSpacing.sm.w, trailing!],
      ],
    );
  }
}
