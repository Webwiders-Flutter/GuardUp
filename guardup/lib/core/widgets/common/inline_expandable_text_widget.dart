import 'package:flutter/material.dart';

// class InlineExpandableTextWidget extends StatelessWidget {
//   final String text;
//   final TextStyle style;
//   final TextStyle actionStyle;
//   final int maxLines;
//   final String seeMoreText;
//   final String seeLessText;
//
//   final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(false);
//
//   InlineExpandableTextWidget({
//     super.key,
//     required this.text,
//     required this.style,
//     required this.actionStyle,
//     this.maxLines = 2,
//     this.seeMoreText = ' ... See more',
//     this.seeLessText = ' See less',
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (text.isEmpty) return const SizedBox.shrink();
//
//     return ValueListenableBuilder<bool>(
//       valueListenable: _isExpandedNotifier,
//       builder: (context, isExpanded, child) {
//         return LayoutBuilder(
//           builder: (context, constraints) {
//             final textDirection = Directionality.of(context);
//             final span = TextSpan(text: text, style: style);
//             final tp = TextPainter(
//               text: span,
//               maxLines: maxLines,
//               textDirection: textDirection,
//             )..layout(maxWidth: constraints.maxWidth);
//
//             if (!tp.didExceedMaxLines) {
//               return Text.rich(span);
//             }
//
//             if (isExpanded) {
//               return GestureDetector(
//                 onTap: () => _isExpandedNotifier.value = false,
//                 child: Text.rich(
//                   TextSpan(
//                     text: text,
//                     style: style,
//                     children: [TextSpan(text: seeLessText, style: actionStyle)],
//                   ),
//                 ),
//               );
//             }
//
//             final seeMoreSpan = TextSpan(text: seeMoreText, style: actionStyle);
//             final seeMoreTp = TextPainter(
//               text: seeMoreSpan,
//               textDirection: textDirection,
//             )..layout(maxWidth: constraints.maxWidth);
//
//             final pos = tp
//                 .getPositionForOffset(
//                   Offset(
//                     constraints.maxWidth - seeMoreTp.width,
//                     tp.size.height - (tp.preferredLineHeight / 2),
//                   ),
//                 )
//                 .offset;
//
//             final truncatedText = (pos > 0 && pos < text.length)
//                 ? text.substring(0, pos).trimRight()
//                 : text;
//
//             return GestureDetector(
//               onTap: () => _isExpandedNotifier.value = true,
//               child: Text.rich(
//                 TextSpan(
//                   text: truncatedText,
//                   style: style,
//                   children: [seeMoreSpan],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }

import 'package:readmore/readmore.dart';

class InlineExpandableTextWidget extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextStyle actionStyle;
  final int maxLines;
  final String seeMoreText;
  final String seeLessText;

  const InlineExpandableTextWidget({
    super.key,
    required this.text,
    required this.style,
    required this.actionStyle,
    this.maxLines = 2,
    this.seeMoreText = 'See more',
    this.seeLessText = 'See less',
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return ReadMoreText(
      text,
      trimMode: TrimMode.Line,
      trimLines: maxLines,
      trimCollapsedText: '... $seeMoreText',
      trimExpandedText: seeLessText,
      style: style,
      moreStyle: actionStyle,
      lessStyle: actionStyle,
      textAlign: TextAlign.start,
    );
  }
}
