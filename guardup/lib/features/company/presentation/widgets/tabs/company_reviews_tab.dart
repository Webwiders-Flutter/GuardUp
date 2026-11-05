import 'package:flutter/material.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/state/api_state.dart';
import '/features/rating_and_reviews/rating_and_reviews.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.state.dart';

/// Tab content rendering verified customer reviews and ratings for this security company.
class CompanyReviewsTab extends StatelessWidget {
  final List<ReviewModel>? reviews;

  const CompanyReviewsTab({super.key, this.reviews});

  @override
  Widget build(BuildContext context) {
    final effectiveReviews = reviews ?? ReviewModel.fakeData;

    return AppPagination<ReviewModel>.list(
      state: PaginationState<ReviewModel>(
        items: effectiveReviews,
        total: effectiveReviews.length,
        status: const ApiState.success(null),
      ),
      header: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Text(
            'Review and Rating',
            style: context.textTheme.titleSmall?.colour(context.colors.outline),
          ),
          AppSpacing.md.h,
        ],
      ),
      padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
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
