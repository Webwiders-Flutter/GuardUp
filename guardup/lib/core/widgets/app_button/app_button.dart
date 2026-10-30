import 'package:flutter/material.dart';
import 'package:guardup/core/app_types/button_type.dart';

import '../../constants/app_fonts.dart';

class AppButton extends StatelessWidget {
  final double? height;
  final double? width;
  final double? borderRadius;
  final double? elevation;
  final double? borderWidth;

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  final Color? splashColor;
  final Color? buttonColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? disabledColor;
  final Color? disabledTextColor;

  final bool isContentSizeButton;
  final bool isLoading;
  final bool isGradient;
  final bool isDisabled;
  final bool isSizeZero;

  final VoidCallback? onPressed;
  final Widget? child;
  final String? text;
  final TextStyle? style;
  final AppButtonType appButtonType;

  final LinearGradient? linearGradient;
  final List<BoxShadow>? boxShadow;

  const AppButton({
    super.key,
    this.height,
    this.width,
    this.margin,
    this.padding,
    this.borderRadius,
    this.isContentSizeButton = true,
    this.isLoading = false,
    this.isSizeZero = false,
    this.splashColor,
    this.buttonColor,
    this.borderColor,
    this.textColor,
    this.disabledColor,
    this.disabledTextColor,
    this.elevation,
    this.appButtonType = AppButtonType.elevated,
    this.onPressed,
    this.child,
    this.borderWidth,
    this.linearGradient,
    this.isGradient = false,
    this.isDisabled = false,
    this.text,
    this.style,
    this.boxShadow,
  }) : assert(text != null || child != null, "Provide either text or child");

  bool get _isEnabled => onPressed != null && !isLoading && !isDisabled;

  double get _height => isContentSizeButton ? (height ?? 40) : (height ?? 50);

  double? get _width =>
      isContentSizeButton ? width : (width ?? double.infinity);

  double get _radius => borderRadius ?? (isContentSizeButton ? 8 : 12);

  double get _borderWidth => borderWidth ?? 1.5;

  double get _elevation =>
      elevation ?? (appButtonType == AppButtonType.elevated ? 2 : 0);

  EdgeInsetsGeometry get _padding =>
      padding ?? const EdgeInsets.symmetric(horizontal: 16);

  EdgeInsetsGeometry get _margin => margin ?? EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final button = _buildButtonByType(context);

    // Apply margin and constraints
    return Container(
      height: isContentSizeButton ? null : _height,
      width: _width,
      margin: _margin,
      child: button,
    );
  }

  Widget _buildButtonByType(BuildContext context) {
    switch (appButtonType) {
      case AppButtonType.elevated:
        return _buildElevated(context);
      case AppButtonType.outline:
        return _buildOutline(context);
      case AppButtonType.text:
        return _buildText(context);
    }
  }

  // ================= ELEVATED BUTTON =================

  Widget _buildElevated(BuildContext context) {
    final effectiveColor = _getEffectiveColor(context);
    final effectiveTextColor = _getEffectiveTextColor(context);

    return ElevatedButton(
      onPressed: _isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        elevation: _elevation,
        padding: _padding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(
            color: borderColor ?? Colors.transparent,
            width: _borderWidth,
          ),
        ),
        minimumSize: isSizeZero ? Size.zero : null,
        backgroundColor: isGradient ? Colors.transparent : effectiveColor,
        foregroundColor: splashColor ?? effectiveTextColor,
        disabledBackgroundColor: disabledColor ?? Colors.grey[300],
        disabledForegroundColor: disabledTextColor ?? Colors.grey[600],
        shadowColor: Colors.transparent,
      ),
      child: _buildInkDecoration(
        context,
        child: _buildChild(context, effectiveTextColor),
      ),
    );
  }

  // ================= OUTLINE BUTTON =================

  Widget _buildOutline(BuildContext context) {
    final effectiveColor = _getEffectiveColor(context);
    final effectiveTextColor = _getEffectiveTextColor(context);
    final effectiveBorderColor = borderColor ?? effectiveColor;

    return OutlinedButton(
      onPressed: _isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        elevation: _elevation,
        padding: _padding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        side: BorderSide(
          width: _borderWidth,
          color: _isEnabled
              ? effectiveBorderColor
              : (disabledColor ?? Colors.grey[400]!),
        ),
        backgroundColor: buttonColor ?? Colors.transparent,
        foregroundColor: splashColor ?? effectiveTextColor,
        disabledBackgroundColor: disabledColor ?? Colors.transparent,
        disabledForegroundColor: disabledTextColor ?? Colors.grey[600],
      ),
      child: _buildInkDecoration(
        context,
        child: _buildChild(context, effectiveTextColor),
      ),
    );
  }

  // ================= TEXT BUTTON =================

  Widget _buildText(BuildContext context) {
    final effectiveTextColor = _getEffectiveTextColor(context);

    return TextButton(
      onPressed: _isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        padding: _padding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        foregroundColor: splashColor ?? effectiveTextColor,
        disabledForegroundColor: disabledTextColor ?? Colors.grey[600],
      ),
      child: _buildInkDecoration(
        context,
        child: _buildChild(context, effectiveTextColor),
      ),
    );
  }

  // ================= INK DECORATION (for gradients & shadows) =================

  Widget _buildInkDecoration(BuildContext context, {required Widget child}) {
    Widget buttonContent = child;

    // Apply gradient or custom decoration
    if (isGradient && appButtonType == AppButtonType.elevated) {
      buttonContent = Container(
        decoration: BoxDecoration(
          gradient: _getGradient(context),
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: boxShadow,
        ),
        child: child,
      );
    } else if (boxShadow != null && appButtonType == AppButtonType.elevated) {
      buttonContent = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          boxShadow: boxShadow,
        ),
        child: child,
      );
    }

    return buttonContent;
  }

  // ================= COMMON CHILD WIDGET =================

  Widget _buildChild(BuildContext context, Color defaultTextColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? defaultTextColor,
          ),
        ),
      );
    }

    if (child != null) {
      return child!;
    }

    final effectiveStyle =
        style ??
        TextStyle(
          fontSize: isContentSizeButton ? 14 : 16,
          fontWeight: FontWeight.w600,
          fontFamily: AppFonts.defultFont,
          color: _getEffectiveTextColor(context),
        );

    return Text(
      text!,
      style: effectiveStyle,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  // ================= HELPER METHODS =================

  Color _getEffectiveColor(BuildContext context) {
    if (buttonColor != null) return buttonColor!;

    switch (appButtonType) {
      case AppButtonType.elevated:
        return Theme.of(context).primaryColor;
      case AppButtonType.outline:
      case AppButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getEffectiveTextColor(BuildContext context) {
    if (textColor != null) return textColor!;

    switch (appButtonType) {
      case AppButtonType.elevated:
        return Colors.white;
      case AppButtonType.outline:
      case AppButtonType.text:
        return Theme.of(context).primaryColor;
    }
  }

  LinearGradient _getGradient(BuildContext context) {
    if (linearGradient != null) return linearGradient!;

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Theme.of(context).primaryColor,
        Theme.of(context).primaryColor.withValues(alpha: 0.8),
      ],
    );
  }
}

// ================= EXTENSION FOR EASY USAGE =================

extension AppButtonExtension on BuildContext {
  // Quick access to themed button colors
  Color get appButtonPrimaryColor => Theme.of(this).primaryColor;
  Color get appButtonSecondaryColor => Theme.of(this).colorScheme.secondary;

  // Common button styles
  ButtonStyle get appButtonRoundedStyle => ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );
}
