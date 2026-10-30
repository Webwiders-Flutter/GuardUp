import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/app_fonts.dart';

class CustomRichText extends StatelessWidget {
  /// Texts
  final String? firstText;
  final String? secondText;
  final String? thirdText;
  final String? fourthText;
  final String? fifthText;

  /// Text Styles
  final TextStyle? firstStyle;
  final TextStyle? secondStyle;
  final TextStyle? thirdStyle;
  final TextStyle? fourthStyle;
  final TextStyle? fifthStyle;

  /// Text Colors
  final Color? firstColor;
  final Color? secondColor;
  final Color? thirdColor;
  final Color? fourthColor;
  final Color? fifthColor;

  /// Underline Colors
  final Color? firstUnderlineColor;
  final Color? secondUnderlineColor;
  final Color? thirdUnderlineColor;
  final Color? fourthUnderlineColor;
  final Color? fifthUnderlineColor;

  /// Font Sizes
  final double? firstFontSize;
  final double? secondFontSize;
  final double? thirdFontSize;
  final double? fourthFontSize;
  final double? fifthFontSize;

  /// Font Family
  final String? firstFontFamily;
  final String? secondFontFamily;
  final String? thirdFontFamily;
  final String? fourthFontFamily;
  final String? fifthFontFamily;

  /// Underline
  final bool firstUnderline;
  final bool secondUnderline;
  final bool thirdUnderline;
  final bool fourthUnderline;
  final bool fifthUnderline;

  /// Text Alignment
  final TextAlign textAlign;

  /// Tap Events
  final VoidCallback? onFirstTap;
  final VoidCallback? onSecondTap;
  final VoidCallback? onThirdTap;
  final VoidCallback? onFourthTap;
  final VoidCallback? onFifthTap;

  const CustomRichText({
    super.key,
    this.firstText,
    this.secondText,
    this.thirdText,
    this.fourthText,
    this.fifthText,
    this.firstStyle,
    this.secondStyle,
    this.thirdStyle,
    this.fourthStyle,
    this.fifthStyle,
    this.firstColor,
    this.secondColor,
    this.thirdColor,
    this.fourthColor,
    this.fifthColor,
    this.firstUnderlineColor,
    this.secondUnderlineColor,
    this.thirdUnderlineColor,
    this.fourthUnderlineColor,
    this.fifthUnderlineColor,
    this.firstFontSize,
    this.secondFontSize,
    this.thirdFontSize,
    this.fourthFontSize,
    this.fifthFontSize,
    this.firstFontFamily,
    this.secondFontFamily,
    this.thirdFontFamily,
    this.fourthFontFamily,
    this.fifthFontFamily,
    this.firstUnderline = false,
    this.secondUnderline = false,
    this.thirdUnderline = false,
    this.fourthUnderline = false,
    this.fifthUnderline = false,
    this.textAlign = TextAlign.start,
    this.onFirstTap,
    this.onSecondTap,
    this.onThirdTap,
    this.onFourthTap,
    this.onFifthTap,
  });

  TextSpan _buildSpan({
    required String? text,
    required TextStyle? style,
    required Color? color,
    required double? fontSize,
    required String? fontFamily,
    required bool underline,
    required Color? underlineColor,
    required VoidCallback? onTap,
  }) {
    if (text == null) return const TextSpan(text: '');

    return TextSpan(
      text: text,
      style:
          style ??
          TextStyle(
            color: color ?? AppColors.blackColor,
            fontSize: fontSize ?? 16,
            fontFamily: fontFamily ?? AppFonts.defultFont,
            decoration: underline
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: underlineColor ?? color,
          ),
      recognizer: onTap != null
          ? (TapGestureRecognizer()..onTap = onTap)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: RichText(
        textAlign: textAlign,
        text: TextSpan(
          children: [
            _buildSpan(
              text: firstText,
              style: firstStyle,
              color: firstColor,
              fontSize: firstFontSize,
              fontFamily: firstFontFamily,
              underline: firstUnderline,
              underlineColor: firstUnderlineColor,
              onTap: onFirstTap,
            ),
            _buildSpan(
              text: secondText,
              style: secondStyle,
              color: secondColor,
              fontSize: secondFontSize,
              fontFamily: secondFontFamily,
              underline: secondUnderline,
              underlineColor: secondUnderlineColor,
              onTap: onSecondTap,
            ),
            _buildSpan(
              text: thirdText,
              style: thirdStyle,
              color: thirdColor,
              fontSize: thirdFontSize,
              fontFamily: thirdFontFamily,
              underline: thirdUnderline,
              underlineColor: thirdUnderlineColor,
              onTap: onThirdTap,
            ),
            _buildSpan(
              text: fourthText,
              style: fourthStyle,
              color: fourthColor,
              fontSize: fourthFontSize,
              fontFamily: fourthFontFamily,
              underline: fourthUnderline,
              underlineColor: fourthUnderlineColor,
              onTap: onFourthTap,
            ),
            _buildSpan(
              text: fifthText,
              style: fifthStyle,
              color: fifthColor,
              fontSize: fifthFontSize,
              fontFamily: fifthFontFamily,
              underline: fifthUnderline,
              underlineColor: fifthUnderlineColor,
              onTap: onFifthTap,
            ),
          ],
        ),
      ),
    );
  }
}
