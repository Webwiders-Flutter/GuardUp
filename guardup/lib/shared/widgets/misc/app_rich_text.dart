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

class AppRichText extends StatefulWidget {
  final List<AppTextSpan> spans;
  final TextAlign textAlign;

  const AppRichText({
    super.key,
    required this.spans,
    this.textAlign = TextAlign.start,
  });

  @override
  State<AppRichText> createState() => _AppRichTextState();
}

class _AppRichTextState extends State<AppRichText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final defaultStyle = context.textTheme.bodyMedium!.increaseSize(1);

    return Text.rich(
      TextSpan(
        style: defaultStyle,
        children: widget.spans.map((span) {
          final isClickable = span.onTap != null;
          TapGestureRecognizer? recognizer;

          if (isClickable) {
            recognizer = TapGestureRecognizer()
              ..onTap = () {
                HapticFeedback.lightImpact();
                span.onTap?.call();
              };
            _recognizers.add(recognizer);
          }

          return TextSpan(
            text: span.text,
            style: _resolveStyle(
              defaultStyle: defaultStyle,
              span: span,
              primaryColor: context.colors.primary,
              isClickable: isClickable,
            ),
            recognizer: recognizer,
          );
        }).toList(),
      ),
      textAlign: widget.textAlign,
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
          span.decoration ??
          style?.decoration ??
          (isClickable ? TextDecoration.underline : defaultStyle.decoration),

      // Decoration color
      decorationColor:
          span.decorationColor ??
          style?.decorationColor ??
          (isClickable ? primaryColor : defaultStyle.color),
    );
  }
}
