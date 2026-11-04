import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/model/plan.model.dart';

/// A luxury selectable membership plan card matching GuardUp design standards.
class PlanSelectionCard extends StatelessWidget {
  /// The plan model data for this card.
  final PlanModel plan;

  /// Whether this plan is currently selected.
  final bool isSelected;

  /// Whether this plan is the user's currently active membership plan.
  final bool isCurrentPlan;

  /// Optional override text for the top-right badge.
  final String? badgeText;

  /// Optional custom background color for the top-right badge.
  final Color? badgeColor;

  /// Optional custom text color for the top-right badge.
  final Color? badgeTextColor;

  /// Optional booking amount to calculate and display the instant savings strip.
  final double? bookingAmount;

  /// Optional callback invoked when the card is tapped.
  final VoidCallback? onTap;

  const PlanSelectionCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.isCurrentPlan = false,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.bookingAmount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppRadius.lg);

    // Resolve top right badge
    final String? effectiveBadge = isCurrentPlan
        ? 'ACTIVE PLAN'
        : (badgeText ?? plan.badge);

    final Color effectiveBadgeColor = isCurrentPlan
        ? context.colors.success
        : (badgeColor ?? context.colors.primary);

    final Color effectiveBadgeTextColor = isCurrentPlan
        ? context.colors.onSurface
        : (badgeTextColor ?? context.colors.onPrimary);

    return ClipRRect(
      borderRadius: cardRadius,
      child: Stack(
        children: [
          // 1. Base card container with outline / gold selection border
          WrapperCard(
            onTap: onTap,
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.outlineVariant,
              width: isSelected ? 1.5 : 1.2,
            ),
            padding: AppSpacing.lg.allPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Discount badge, Plan Title/Price, Radio Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Discount Box (e.g. 20% OFF)
                    QuickContainer(
                      w: 52,
                      h: 52,
                      radius: AppRadius.md,
                      color: context.colors.surfaceContainerHigh.withValues(
                        alpha: 0.8,
                      ),
                      border: Border.all(
                        color: context.colors.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                        width: 1,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            plan.discountPercentage.percentageText,
                            style: context.textTheme.titleSmall?.bold().colour(
                              context.colors.primary,
                            ),
                          ),
                          Text(
                            'OFF',
                            style: context.textTheme.labelSmall?.colour(
                              context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.md.w,

                    // Title and Monthly Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: context.textTheme.titleMedium?.bold(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppSpacing.xxs.h,
                          Text(
                            '${plan.monthlyPrice.toUsd} / month',
                            style: context.textTheme.bodySmall?.colour(
                              context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.sm.w,

                    // Radio Selection Indicator
                    QuickContainer(
                      w: 24,
                      h: 24,
                      radius: AppRadius.full,
                      border: Border.all(
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.primary.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? QuickContainer(
                              w: 12,
                              h: 12,
                              radius: AppRadius.full,
                              color: context.colors.primary,
                            )
                          : null,
                    ),
                  ],
                ),

                // Optional Instant Booking Saving Strip
                if (bookingAmount != null && bookingAmount! > 0) ...[
                  AppSpacing.md.h,
                  QuickContainer(
                    w: double.infinity,
                    px: AppSpacing.md,
                    py: AppSpacing.sm,
                    radius: AppRadius.md,
                    color: context.colors.surfaceDim,
                    border: Border.all(
                      color: context.colors.outlineVariant.withValues(
                        alpha: 0.35,
                      ),
                      width: 1,
                    ),
                    child: AppRichText(
                      spans: [
                        AppTextSpan(
                          text: 'Instant booking saving: ',
                          style: context.textTheme.bodySmall?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                        ),
                        AppTextSpan(
                          text:
                              'Save ${plan.calculateSavings(bookingAmount!).toUsd} (Pay ${plan.calculatePayable(bookingAmount!).toUsd})',
                          style: context.textTheme.bodySmall
                              ?.bold()
                              .colour(context.colors.primary)
                              .increaseSize(1),
                        ),
                      ],
                    ),
                  ),
                ],

                // Features List
                AppSpacing.md.h,
                ...plan.features.map(
                  (feature) => Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: (plan.featureIcon ?? Assets.svg.checked).svg(
                            width: AppSizes.iconXs,
                            height: AppSizes.iconXs,
                          ),
                        ),
                        AppSpacing.sm.w,
                        Expanded(
                          child: Text(
                            feature,
                            style: context.textTheme.bodySmall?.colour(
                              context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Corner Ribbon Badge (e.g. ★ MOST POPULAR or ACTIVE PLAN)
          if (effectiveBadge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: effectiveBadgeColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppRadius.lg),
                    bottomLeft: Radius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  effectiveBadge,
                  style: context.textTheme.labelSmall
                      ?.colour(effectiveBadgeTextColor)
                      .textSpacing(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
