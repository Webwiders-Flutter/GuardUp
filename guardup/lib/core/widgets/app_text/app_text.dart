import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_fonts.dart';

class AppText extends StatelessWidget {
  final String text;

  /// Priority 1 → Full custom style
  final TextStyle? style;

  /// Priority 2 → Theme type
  final AppTextType? type;

  /// Overrides
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final double? height;
  final double? letterSpacing;

  /// Underline
  final bool isShowUnderLine;

  /// Underline Color
  final Color? underlineColor;

  /// Behavior
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.type,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.height,
    this.letterSpacing,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.textDirection,
    this.isShowUnderLine = false,
    this.underlineColor,
  });

  TextStyle _getThemeStyle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    switch (type ?? AppTextType.bodyMedium) {
      case AppTextType.headlineLarge:
        return textTheme.headlineLarge ?? const TextStyle();

      case AppTextType.headlineMedium:
        return textTheme.headlineMedium ?? const TextStyle();

      case AppTextType.headlineSmall:
        return textTheme.headlineSmall ?? const TextStyle();

      case AppTextType.displayLarge:
        return textTheme.displayLarge ?? const TextStyle();

      case AppTextType.displayMedium:
        return textTheme.displayMedium ?? const TextStyle();

      case AppTextType.displaySmall:
        return textTheme.displaySmall ?? const TextStyle();

      case AppTextType.bodyLarge:
        return textTheme.bodyLarge ?? const TextStyle();

      case AppTextType.bodyMedium:
        return textTheme.bodyMedium ?? const TextStyle();

      case AppTextType.bodySmall:
        return textTheme.bodySmall ?? const TextStyle();

      case AppTextType.titleLarge:
        return textTheme.titleLarge ?? const TextStyle();

      case AppTextType.titleMedium:
        return textTheme.titleMedium ?? const TextStyle();

      case AppTextType.titleSmall:
        return textTheme.titleSmall ?? const TextStyle();

      case AppTextType.labelLarge:
        return textTheme.labelLarge ?? const TextStyle();

      case AppTextType.labelMedium:
        return textTheme.labelMedium ?? const TextStyle();

      case AppTextType.labelSmall:
        return textTheme.labelSmall ?? const TextStyle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? _getThemeStyle(context);

    final finalStyle = baseStyle.copyWith(
      color: color ?? baseStyle.color,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
      fontSize: fontSize ?? baseStyle.fontSize,
      height: height ?? baseStyle.height,
      letterSpacing: letterSpacing ?? baseStyle.letterSpacing,
      fontFamily: AppFonts.defultFont,

      decoration: isShowUnderLine
          ? TextDecoration.underline
          : TextDecoration.none,

      decorationColor: underlineColor ?? color,

      decorationThickness: 1.5,
    );

    final hasRtl = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(text);
    final isRtl = hasRtl && Bidi.startsWithRtl(text);
    final resolvedDirection =
        textDirection ??
        (hasRtl ? (isRtl ? TextDirection.rtl : TextDirection.ltr) : null);
    final displayText = hasRtl
        ? (isRtl ? BidiFormatter.RTL() : BidiFormatter.LTR()).wrapWithUnicode(
            text,
          )
        : text;

    return Text(
      displayText,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: finalStyle,
      textDirection: resolvedDirection,
    );
  }
}
