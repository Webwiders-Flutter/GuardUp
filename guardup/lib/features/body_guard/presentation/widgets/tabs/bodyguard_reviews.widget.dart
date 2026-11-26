import 'package:flutter/material.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/rating_and_reviews/rating_and_reviews.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.state.dart';

/// Tab content widget rendering the client feedback and review cards for a bodyguard profile.
class BodyguardReviewsWidget extends StatelessWidget {
  final List<ReviewModel>? reviews;

  const BodyguardReviewsWidget({super.key, this.reviews});

  @override
  Widget build(BuildContext context) {
    final effectiveReviews = reviews ?? reviewFixtures;

    return AppPagination<ReviewModel>.list(
      state: PaginationState<ReviewModel>(
        items: effectiveReviews,
        total: effectiveReviews.length,
        status: const ApiState.success(null),
      ),
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => AppSpacing.md.h,
      emptyBuilder: (context) => Padding(
        padding: AppSpacing.xxl.allPadding,
        child: Center(
          child: Text(
            'No reviews yet',
            style: context.textTheme.bodyMedium?.colour(
              context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
      itemBuilder: (context, review, index) {
        return ReviewCard(review: review, eventTypeLabel: review.serviceTag);
      },
    );
  }
}
