import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/model/review.model.dart';

/// A single review card displaying reviewer name, star rating, verified badge,
/// relative timestamp, optional event type label, and the review body text.
///
/// Matches the GuardUp luxury dark-card design language.
class ReviewCard extends StatelessWidget {
  /// The review data to render.
  final ReviewModel review;

  /// Optional event/service type label shown beside the timestamp
  /// (e.g. "VIP Private Event"). Falls back to the booking ID if null.
  final String? eventTypeLabel;

  /// Whether to show the gold "Verified" badge on the right.
  final bool showVerifiedBadge;

  /// Optional tap callback for the entire card.
  final VoidCallback? onTap;

  const ReviewCard({
    super.key,
    required this.review,
    this.eventTypeLabel,
    this.showVerifiedBadge = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleLabel =
        eventTypeLabel ?? review.serviceTag ?? review.bookingId;

    return WrapperCard(
      onTap: onTap,
      padding: AppSpacing.lg.allPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ----------------------------------------------------------------
          // Row 1: Reviewer name + star rating  |  Verified badge
          // ----------------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Reviewer Name
              Text(
                review.from.name,
                style: context.textTheme.titleSmall?.bold(),
              ),
              AppSpacing.xs.w,

              // Star rating
              Text(
                review.rating.toStringAsFixed(1),
                style: context.textTheme.labelMedium?.bold().colour(
                  context.colors.primary,
                ),
              ),
              AppSpacing.xxs.w,
              Icon(
                Icons.star_rounded,
                size: AppSizes.iconXs,
                color: context.colors.primary,
              ),

              const Spacer(),

              // Verified badge
              if (showVerifiedBadge) const _VerifiedBadge(),
            ],
          ),

          AppSpacing.xs.h,

          // ----------------------------------------------------------------
          // Row 2: Time ago  •  Event type label
          // ----------------------------------------------------------------
          Row(
            children: [
              Text(
                review.customFormattedTimeAgo ?? review.createdAt.timeAgo,
                style: context.textTheme.labelSmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              if (subtitleLabel != null) ...{
                Text(
                  ' • ',
                  style: context.textTheme.labelSmall?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    subtitleLabel,
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              },
            ],
          ),

          AppSpacing.md.h,

          // ----------------------------------------------------------------
          // Row 3: Review description in quotes
          // ----------------------------------------------------------------
          Text(
            '"${review.reviewDescription}"',
            style: context.textTheme.bodySmall
                ?.colour(context.colors.onSurfaceVariant)
                .lineHeight(1.4),
          ),
        ],
      ),
    );
  }
}

/// Gold-outlined "Verified" pill badge matching the GuardUp luxury design.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return QuickContainer(
      radius: AppRadius.full,
      color: context.colors.transparent,
      border: Border.all(
        color: context.colors.primary.withValues(alpha: 0.6),
        width: 1.0,
      ),
      px: AppSpacing.sm,
      py: AppSpacing.xxs,
      child: Text(
        'Verified',
        style: context.textTheme.labelSmall?.semiBold().colour(
          context.colors.primary,
        ),
      ),
    );
  }
}
