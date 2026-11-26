import 'package:flutter/material.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Displays text truncated to [maxLines] with an inline "Read More" /
/// "Show Less" toggle when the text overflows.
class AppExpandableText extends StatefulWidget {
  const AppExpandableText({
    super.key,
    required this.text,
    this.maxLines = 4,
    this.style,
    this.readMoreLabel = 'Read More',
    this.showLessLabel = 'Show Less',
  });

  final String text;
  final int maxLines;
  final TextStyle? style;
  final String readMoreLabel;
  final String showLessLabel;

  @override
  State<AppExpandableText> createState() => _AppExpandableTextState();
}

class _AppExpandableTextState extends State<AppExpandableText> {
  final _isExpandedNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        widget.style ?? context.textTheme.bodySmall?.lineHeight(1.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          textDirection: Directionality.of(context),
          maxLines: widget.maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        final canOverflow = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _isExpandedNotifier,
              builder: (context, isExpanded, _) {
                return Text(
                  widget.text,
                  maxLines: (isExpanded || !canOverflow)
                      ? null
                      : widget.maxLines,
                  overflow: (isExpanded || !canOverflow)
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: effectiveStyle,
                );
              },
            ),
            if (canOverflow) ...[
              AppSpacing.sm.h,
              ValueListenableBuilder<bool>(
                valueListenable: _isExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return GestureDetector(
                    onTap: () =>
                        _isExpandedNotifier.value = !_isExpandedNotifier.value,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isExpanded
                              ? widget.showLessLabel
                              : widget.readMoreLabel,
                          style: context.textTheme.labelMedium?.colour(
                            context.colors.primary,
                          ),
                        ),
                        AppSpacing.xxs.w,
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.chevron_right_rounded,
                          size: AppSizes.iconXs,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
