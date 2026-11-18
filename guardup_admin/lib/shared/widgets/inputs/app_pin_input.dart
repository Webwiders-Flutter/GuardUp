import 'package:guardup_admin/core/constants/app_radius.dart';
import 'package:guardup_admin/core/constants/app_spacing.dart' show AppSpacing;
import 'package:guardup_admin/core/extensions/textstyle_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../../../core/extensions/context.extension.dart';

/// A customizable, design-system compliant PIN/OTP input widget wrapping [Pinput].
class AppPinInput extends StatelessWidget {
  /// Length of the OTP/PIN (defaults to 6)
  final int length;

  /// Controller for managing the entered pin
  final TextEditingController? controller;

  /// FocusNode for controlling input focus
  final FocusNode? focusNode;

  /// Triggered when all digits are filled
  final ValueChanged<String>? onCompleted;

  /// Triggered when the pin value changes
  final ValueChanged<String>? onChanged;

  /// Form field validator
  final FormFieldValidator<String>? validator;

  /// Whether to auto-focus when screen opens
  final bool autofocus;

  /// Whether the input is enabled
  final bool enabled;

  /// Whether the input is read only
  final bool readOnly;

  /// Whether digits are obscured
  final bool obscureText;

  /// Obscuring character
  final String obscuringCharacter;

  /// Keyboard type (defaults to TextInputType.number)
  final TextInputType keyboardType;

  /// Text formatters applied to input
  final List<TextInputFormatter>? inputFormatters;

  /// Alignment of pin cells across the row
  final MainAxisAlignment mainAxisAlignment;

  /// Width of each pin box
  final double width;

  /// Height of each pin box
  final double height;

  /// Border radius of each pin box
  final BorderRadius? borderRadius;

  /// Default background fill color of pin boxes
  final Color? fillColor;

  /// Background fill color when focused
  final Color? focusedFillColor;

  /// Border color for default state
  final Color? borderColor;

  /// Border color when focused
  final Color? focusedBorderColor;

  /// Custom text style for digits
  final TextStyle? textStyle;

  /// Explicit default pin theme override
  final PinTheme? defaultPinTheme;

  /// Explicit focused pin theme override
  final PinTheme? focusedPinTheme;

  /// Explicit submitted pin theme override
  final PinTheme? submittedPinTheme;

  /// Explicit error pin theme override
  final PinTheme? errorPinTheme;

  /// Error text to display
  final String? errorText;

  /// Whether to show the cursor
  final bool showCursor;

  /// Custom cursor widget
  final Widget? cursor;

  /// Haptic feedback on input
  final HapticFeedbackType hapticFeedbackType;

  /// Automatically dismiss keyboard on completion
  final bool closeKeyboardWhenCompleted;

  /// Mode for automatic validation
  final PinputAutovalidateMode pinputAutovalidateMode;

  const AppPinInput({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onCompleted,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.width = AppSpacing.xxxl + AppSpacing.lg,
    this.height = AppSpacing.xxxl + AppSpacing.xxl - (AppSpacing.xs / 2),
    this.borderRadius,
    this.fillColor,
    this.focusedFillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.textStyle,
    this.defaultPinTheme,
    this.focusedPinTheme,
    this.submittedPinTheme,
    this.errorPinTheme,
    this.errorText,
    this.showCursor = true,
    this.cursor,
    this.hapticFeedbackType = HapticFeedbackType.lightImpact,
    this.closeKeyboardWhenCompleted = true,
    this.pinputAutovalidateMode = PinputAutovalidateMode.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.mdRadius;
    final effectiveFill =
        fillColor ?? context.colors.borderLight.withValues(alpha: 0.45);
    final effectiveTextStyle =
        textStyle ??
        context.textTheme.headlineSmall?.bold().colour(
          context.colors.onSurface,
        );

    final basePinTheme =
        defaultPinTheme ??
        PinTheme(
          width: width,
          height: height,
          textStyle: effectiveTextStyle,
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: effectiveRadius,
            border: Border.all(
              color: borderColor ?? context.colors.transparent,
              width: 1.0,
            ),
          ),
        );

    final activeFocusedPinTheme =
        focusedPinTheme ??
        basePinTheme.copyWith(
          decoration: basePinTheme.decoration?.copyWith(
            color: focusedFillColor ?? context.colors.surface,
            border: Border.all(
              color: focusedBorderColor ?? context.colors.primary,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (focusedBorderColor ?? context.colors.primary)
                    .withValues(alpha: 0.1),
                blurRadius: AppSpacing.xs,
                offset: const Offset(0, AppSpacing.xs / 2),
              ),
            ],
          ),
        );

    final activeSubmittedPinTheme =
        submittedPinTheme ??
        basePinTheme.copyWith(
          decoration: basePinTheme.decoration?.copyWith(
            color: effectiveFill,
            border: Border.all(
              color: (focusedBorderColor ?? context.colors.primary).withValues(
                alpha: 0.25,
              ),
              width: 1.0,
            ),
          ),
        );

    final activeErrorPinTheme =
        errorPinTheme ??
        basePinTheme.copyWith(
          decoration: basePinTheme.decoration?.copyWith(
            border: Border.all(color: context.colors.error, width: 1.5),
          ),
        );

    return Pinput(
      length: length,
      controller: controller,
      focusNode: focusNode,
      onCompleted: onCompleted,
      onChanged: onChanged,
      validator: validator,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter,
      keyboardType: keyboardType,
      inputFormatters:
          inputFormatters ?? [FilteringTextInputFormatter.digitsOnly],
      mainAxisAlignment: mainAxisAlignment,
      defaultPinTheme: basePinTheme,
      focusedPinTheme: activeFocusedPinTheme,
      submittedPinTheme: activeSubmittedPinTheme,
      errorPinTheme: activeErrorPinTheme,
      errorText: errorText,
      showCursor: showCursor,
      cursor: cursor,
      hapticFeedbackType: hapticFeedbackType,
      closeKeyboardWhenCompleted: closeKeyboardWhenCompleted,
      pinputAutovalidateMode: pinputAutovalidateMode,
    );
  }
}
