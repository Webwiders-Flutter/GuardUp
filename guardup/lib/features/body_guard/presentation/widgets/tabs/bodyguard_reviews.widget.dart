import 'package:flutter/material.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/rating_and_reviews/rating_and_reviews.dart';

/// Tab content widget rendering the client feedback and review cards for a bodyguard profile.
class BodyguardReviewsWidget extends StatelessWidget {
  final List<ReviewModel>? reviews;

  const BodyguardReviewsWidget({
    super.key,
    this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveReviews = reviews ?? ReviewModel.fakeBodyguardReviews;

    if (effectiveReviews.isEmpty) {
      return Padding(
        padding: AppSpacing.xxl.allPadding,
        child: Center(
          child: Text(
            'No reviews yet',
            style: context.textTheme.bodyMedium?.colour(
              context.colors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < effectiveReviews.length; i++) ...[
          ReviewCard(
            review: effectiveReviews[i],
            eventTypeLabel: effectiveReviews[i].serviceTag,
          ),
          if (i < effectiveReviews.length - 1) AppSpacing.md.h,
        ],
        AppSpacing.xl.h,
      ],
    );
  }
}

