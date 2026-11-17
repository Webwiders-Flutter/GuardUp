import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/textstyle_extension.dart';

import '../../../core/extensions/context.extension.dart';

class AppTextSpan {
  final String text;

  /// Optional complete TextStyle override.
  final TextStyle? style;

  /// Optional individual style properties.
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final double? height;
  final TextDecoration? decoration;
  final Color? decorationColor;

  /// Called when this span is tapped.
  final VoidCallback? onTap;

  const AppTextSpan({
    required this.text,
    this.style,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.fontStyle,
    this.letterSpacing,
    this.height,
    this.decoration,
    this.decorationColor,
    this.onTap,
  });
}

class AppRichText extends StatelessWidget {
  final List<AppTextSpan> spans;
  final TextAlign textAlign;

  const AppRichText({
    super.key,
    required this.spans,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = context.textTheme.bodyMedium!
        .increaseSize(1)
        .colour(context.colors.onSurfaceSecondary);

    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: defaultStyle,
        children: spans.map((span) {
          final isClickable = span.onTap != null;

          return TextSpan(
            text: '${span.text} ',
            style: _resolveStyle(
              defaultStyle: defaultStyle,
              span: span,
              primaryColor: context.colors.secondary,
              isClickable: isClickable,
            ),
            recognizer: isClickable
                ? (TapGestureRecognizer()
                    ..onTap = () {
                      HapticFeedback.lightImpact();
                      span.onTap?.call();
                    })
                : null,
          );
        }).toList(),
      ),
    );
  }

  TextStyle _resolveStyle({
    required TextStyle defaultStyle,
    required AppTextSpan span,
    required Color primaryColor,
    required bool isClickable,
  }) {
    final style = span.style;

    return defaultStyle.copyWith(
      // Color
      color:
          span.color ??
          style?.color ??
          (isClickable ? primaryColor : defaultStyle.color),

      // Font size
      fontSize: span.fontSize ?? style?.fontSize ?? defaultStyle.fontSize,

      // Font weight
      fontWeight:
          span.fontWeight ?? style?.fontWeight ?? defaultStyle.fontWeight,

      // Font style
      fontStyle: span.fontStyle ?? style?.fontStyle ?? defaultStyle.fontStyle,

      // Letter spacing
      letterSpacing:
          span.letterSpacing ??
          style?.letterSpacing ??
          defaultStyle.letterSpacing,

      // Line height
      height: span.height ?? style?.height ?? defaultStyle.height,

      // Decoration
      decoration:
          span.decoration ?? style?.decoration ?? defaultStyle.decoration,

      // Decoration color
      decorationColor:
          span.decorationColor ??
          style?.decorationColor ??
          (isClickable ? primaryColor : defaultStyle.color),
    );
  }
}
