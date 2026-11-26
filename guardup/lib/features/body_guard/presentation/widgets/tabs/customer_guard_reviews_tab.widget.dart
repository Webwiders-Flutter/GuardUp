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

  static const List<ReviewItemData> fakeData = [];
}

/// Customer View "Reviews" Tab: Displays operative client feedback and verified ratings.
class CustomerGuardReviewsTabWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final List<ReviewItemData> reviews;

  const CustomerGuardReviewsTabWidget({
    super.key,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.reviews = ReviewItemData.fakeData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating Summary Card
          QuickContainer(
            w: double.infinity,
            p: AppSpacing.md,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: context.colors.onPrimary,
            border: Border.all(
              color: context.colors.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: context.textTheme.headlineMedium
                              ?.bold()
                              .colour(context.colors.onSurface),
                        ),
                        AppSpacing.xs.w,
                        Icon(
                          Icons.star_rounded,
                          color: context.colors.primary,
                          size: 26,
                        ),
                      ],
                    ),
                    AppSpacing.xxs.h,
                    Text(
                      'Based on $totalReviews reviews',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          AppSpacing.lg.h,

          Text(
            'CLIENT FEEDBACK',
            style: context.textTheme.labelMedium
                ?.bold()
                .copyWith(letterSpacing: 0.8)
                .colour(context.colors.onSurfaceVariant),
          ),
          AppSpacing.sm.h,

          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No client reviews yet',
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...reviews.map((review) {
              return QuickContainer(
                w: double.infinity,
                my: 6,
                p: AppSpacing.md,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: context.colors.surfaceContainer,
                border: Border.all(
                  color: context.colors.outlineVariant.withValues(alpha: 0.4),
                  width: 0.8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.authorName,
                          style: context.textTheme.titleSmall?.bold().colour(
                            context.colors.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: context.colors.primary,
                            ),
                            AppSpacing.xxs.w,
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: context.textTheme.labelMedium
                                  ?.bold()
                                  .colour(context.colors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.xxs.h,
                    Text(
                      review.timeAndContext,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.xs.h,
                    Text(
                      review.comment,
                      style: context.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: context.colors.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              );
            }),

          AppSpacing.xxl.h,
        ],
      ),
    );
  }
}
