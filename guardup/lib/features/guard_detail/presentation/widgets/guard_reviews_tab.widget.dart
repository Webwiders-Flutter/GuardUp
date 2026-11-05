import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

class ReviewItemData {
  final String authorName;
  final double rating;
  final String timeAndContext;
  final String comment;

  const ReviewItemData({
    required this.authorName,
    required this.rating,
    required this.timeAndContext,
    required this.comment,
  });
}

/// "Reviews" tab content displaying client feedback and operational performance ratings.
class GuardReviewsTabWidget extends StatelessWidget {
  final List<ReviewItemData> reviews;

  const GuardReviewsTabWidget({
    super.key,
    this.reviews = const [
      ReviewItemData(
        authorName: 'Elena Rostova',
        rating: 5.0,
        timeAndContext: '1 week ago • Late-Night Transit',
        comment: '“Felt completely safe during late-night transit. Michael was punctual, alert, and very professional throughout the escort.”',
      ),
      ReviewItemData(
        authorName: 'Marcus Sterling',
        rating: 4.8,
        timeAndContext: '3 weeks ago • VIP Private Event',
        comment:
            '“Excellent crowd deterrence and calm composure during our event.”',
      ),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REVIEW AND RATING',
          style: context.textTheme.labelMedium
              ?.bold()
              .copyWith(letterSpacing: 0.8)
              .colour(context.colors.onSurfaceVariant),
        ),
        AppSpacing.sm.h,

        ...reviews.map((rev) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: QuickContainer(
              w: double.infinity,
              p: AppSpacing.md,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: context.colors.surfaceContainer,
              border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rev.authorName,
                        style: context.textTheme.titleSmall?.bold().colour(
                          context.colors.onSurface,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rev.rating.toStringAsFixed(1),
                            style: context.textTheme.labelSmall?.colour(
                              context.colors.primary,
                            ),
                          ),
                          AppSpacing.xxs.w,
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: context.colors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.xxs.h,

                  Text(
                    rev.timeAndContext,
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontSize: 10.5)
                        .colour(context.colors.onSurfaceVariant),
                  ),
                  AppSpacing.sm.h,

                  Text(
                    rev.comment,
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontSize: 11.5, height: 1.4)
                        .colour(context.colors.onSurface),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
