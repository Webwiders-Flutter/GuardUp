// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:project/core/utils/extensions_utils/colors_extension.dart';
// import 'package:project/core/utils/extensions_utils/text_style_extension.dart';
// import 'package:responsive_sizer/responsive_sizer.dart';
//
// enum AppOtpShape { box, underline, circle }
//
// class AppOtpField extends StatelessWidget {
//   /// Controller to read / clear the OTP value externally
//   final TextEditingController? controller;
//
//   /// Number of OTP digits
//   final int length;
//
//   /// Fires on every keystroke — receives the current full OTP string
//   final Function(String)? onChanged;
//
//   /// Fires when all fields are filled
//   final Function(String)? onCompleted;
//
//   /// Individual field dimensions
//   final double? fieldWidth;
//   final double? fieldHeight;
//
//   /// Border
//   final double? borderRadius;
//   final Color? borderColor;
//   final Color? focusedBorderColor;
//   final Color? selectedBorderColor;
//   final Color? errorBorderColor;
//   final double borderWidth;
//
//   /// Fill color per state
//   final Color? fillColor;
//   final Color? focusedFillColor;
//   final Color? selectedFillColor;
//
//   /// Text
//   final TextStyle? textStyle;
//   final Color? textColor;
//
//   /// Cursor
//   final Color? cursorColor;
//   final double cursorWidth;
//   final double cursorHeight;
//
//   /// Behavior
//   final bool obscureText;
//   final String obscuringCharacter;
//   final bool enabled;
//   final bool autoFocus;
//   final bool enableActiveFill;
//   final TextInputType keyboardType;
//   final AppOtpShape otpShape;
//
//   /// Animation when a field gets a character
//   final AnimationType animationType;
//
//   const AppOtpField({
//     super.key,
//     this.controller,
//     this.length = 6,
//     this.onChanged,
//     this.onCompleted,
//     this.fieldWidth,
//     this.fieldHeight,
//     this.borderRadius,
//     this.borderColor,
//     this.focusedBorderColor,
//     this.selectedBorderColor,
//     this.errorBorderColor,
//     this.borderWidth = 1.5,
//     this.fillColor,
//     this.focusedFillColor,
//     this.selectedFillColor,
//     this.textStyle,
//     this.textColor,
//     this.cursorColor,
//     this.cursorWidth = 2,
//     this.cursorHeight = 24,
//     this.obscureText = false,
//     this.obscuringCharacter = '●',
//     this.enabled = true,
//     this.autoFocus = true,
//     this.enableActiveFill = true,
//     this.keyboardType = TextInputType.number,
//     this.otpShape = AppOtpShape.box,
//     this.animationType = AnimationType.fade,
//   }) : assert(length > 0, 'length must be greater than 0');
//
//   PinCodeFieldShape get _pinShape {
//     switch (otpShape) {
//       case AppOtpShape.box:
//         return PinCodeFieldShape.box;
//       case AppOtpShape.underline:
//         return PinCodeFieldShape.underline;
//       case AppOtpShape.circle:
//         return PinCodeFieldShape.circle;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final resolvedTextStyle = (textStyle ??
//         context.textStyles.titleLarge ??
//         const TextStyle())
//         .copyWith(
//       color: textColor ?? context.colors.text,
//       fontWeight: FontWeight.w600,
//     );
//
//     return PinCodeTextField(
//       appContext: context,
//       length: length,
//       controller: controller,
//       enabled: enabled,
//       autoFocus: autoFocus,
//       obscureText: obscureText,
//       obscuringCharacter: obscuringCharacter,
//       animationType: animationType,
//       keyboardType: keyboardType,
//       textStyle: resolvedTextStyle,
//       cursorColor: cursorColor ?? context.colors.primary,
//       cursorWidth: cursorWidth,
//       cursorHeight: cursorHeight,
//       enableActiveFill: enableActiveFill,
//       inputFormatters: [
//         keyboardType == TextInputType.number
//             ? FilteringTextInputFormatter.digitsOnly
//             : FilteringTextInputFormatter.singleLineFormatter,
//       ],
//       pinTheme: PinTheme(
//         shape: _pinShape,
//         fieldWidth: fieldWidth ?? 45.px,
//         fieldHeight: fieldHeight ?? 52.px,
//         borderRadius: BorderRadius.circular(borderRadius ?? 10.px),
//         borderWidth: borderWidth,
//
//         // Default state
//         inactiveColor: borderColor ?? context.colors.border,
//         inactiveFillColor: fillColor ?? context.colors.fillColor,
//
//         // Active (typing) state
//         activeColor: focusedBorderColor ?? context.colors.primary,
//         activeFillColor: focusedFillColor ?? context.colors.fillColor,
//
//         // Selected (last filled) state
//         selectedColor: selectedBorderColor ?? context.colors.primary,
//         selectedFillColor: selectedFillColor ?? context.colors.fillColor,
//
//         // Error state
//         errorBorderColor: errorBorderColor ?? context.colors.error,
//       ),
//       onChanged: (value) => onChanged?.call(value),
//       onCompleted: (value) => onCompleted?.call(value),
//     );
//   }
// }
