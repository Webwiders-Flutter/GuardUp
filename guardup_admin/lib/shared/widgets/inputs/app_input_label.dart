import 'package:flutter/material.dart';

import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

class AppFieldLabel extends StatelessWidget {
  final String text;
  final bool isRequired;
  final bool isOptional;
  final TextStyle? labelStyle;

  const AppFieldLabel({
    super.key,
    required this.text,
    this.labelStyle,
    this.isOptional = false,
    this.isRequired = false,
  }) : assert(
         !(isRequired && isOptional),
         "Both isRequired and isOptional cannot be true",
       );

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: labelStyle ?? context.textTheme.labelLarge,
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: (labelStyle ?? context.textTheme.labelLarge)?.colour(
                context.colors.error,
              ),
            ),
          if (isOptional)
            TextSpan(
              text: ' (optional)',
              style: (labelStyle ?? context.textTheme.labelLarge)?.colour(
                context.colors.onSurfaceSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
