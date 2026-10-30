import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/app_fonts.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class ExpandableDescriptionWidget extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableDescriptionWidget({
    super.key,
    required this.text,
    this.maxLines = 3,
  });

  @override
  State<ExpandableDescriptionWidget> createState() =>
      _ExpandableDescriptionWidgetState();
}

class _ExpandableDescriptionWidgetState
    extends State<ExpandableDescriptionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    return LayoutBuilder(
      builder: (context, size) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: AppFonts.defultFont,
            ),
          ),
          maxLines: widget.maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: size.maxWidth);

        final isExceeding = textPainter.didExceedMaxLines;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                widget.text,
                color: Colors.grey,
                fontSize: 14,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? null : TextOverflow.ellipsis,
              ),
              if (isExceeding) ...[
                4.height,
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: AppText(
                    _isExpanded
                        ? (isArabic ? 'عرض أقل' : 'READ LESS')
                        : context.l10n.readMore,
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
