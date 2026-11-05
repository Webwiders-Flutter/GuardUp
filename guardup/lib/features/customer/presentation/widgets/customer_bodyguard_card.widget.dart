import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';
import '../../data/model/customer_home_data.dart';

/// Bodyguard card supporting both the home spotlight view and the full listing view.
class CustomerBodyguardCardWidget extends StatelessWidget {
  final CustomerBodyguardItem item;
  final VoidCallback? onBookNow;
  final VoidCallback? onTap;
  final bool isCompact;

  const CustomerBodyguardCardWidget({
    super.key,
    required this.item,
    this.onBookNow,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final guard = item.model;
    final rateInt = guard.hourlyRate.toInt();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: double.infinity,
        p: AppSpacing.md,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // color: Color(0xFF161B26).withValues(alpha: 0.9),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A202D).withValues(alpha: 0.8),
            Color(0xFF0F131C).withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        child: isCompact
            ? _buildHomeCard(context, guard, rateInt)
            : _buildListCard(context, guard, rateInt),
      ),
    );
  }

  /// Compact card used in Screen 1 (Home Top Bodyguards)
  Widget _buildHomeCard(BuildContext context, dynamic guard, int rateInt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bodyguard Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 68,
                height: 68,
                child: AppImage.asset(
                  assetPath:
                      guard.user.profileImageUrl ??
                      Assets.images.profilePicture.path,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            AppSpacing.md.w,

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            guard.user.name,
                            style: context.textTheme.titleSmall?.bold().colour(
                              context.colors.onSurface,
                            ),
                          ),
                          AppSpacing.xxs.w,
                          Assets.svg.verifiedShieldBadge.svg(
                            width: 14,
                            height: 14,
                            colorFilter: ColorFilter.mode(
                              context.colors.primary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                      // Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: context.colors.primary.withValues(
                              alpha: 0.4,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: context.colors.primary,
                            ),
                            AppSpacing.xxs.w,
                            Text(
                              guard.rating.toStringAsFixed(1),
                              style: context.textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  )
                                  .colour(context.colors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.xxs.h,

                  Text(
                    'Licensed armed, Corporate visits',
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontSize: 11)
                        .colour(context.colors.onSurfaceVariant),
                  ),
                  AppSpacing.xs.h,

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.tagLabels.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceDim,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(
                            color: context.colors.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: context.textTheme.labelSmall
                              ?.copyWith(fontSize: 9.5)
                              .colour(context.colors.onSurfaceVariant),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),

        AppSpacing.sm.h,
        Divider(
          color: context.colors.outlineVariant.withValues(alpha: 0.3),
          height: 1,
        ),
        AppSpacing.sm.h,

        // Price & Book Now Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$$rateInt',
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.onSurface,
                  ),
                ),
                AppSpacing.xxs.w,
                Text(
                  '/hr',
                  style: context.textTheme.bodySmall?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onBookNow,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: context.colors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Book Now',
                  style: context.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 11)
                      .colour(context.colors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Full listing card used in Screen 3 (All Bodyguards)
  Widget _buildListCard(BuildContext context, dynamic guard, int rateInt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bodyguard Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 76,
                height: 84,
                child: AppImage.asset(
                  assetPath:
                      guard.user.profileImageUrl ??
                      Assets.images.profilePicture.path,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            AppSpacing.md.w,

            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Availability Status Badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color:
                                  item.availabilityStatus
                                      .toLowerCase()
                                      .contains('tomorrow')
                                  ? context.colors.warning
                                  : context.colors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.xs.w,
                          Text(
                            item.availabilityStatus,
                            style: context.textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                )
                                .colour(
                                  item.availabilityStatus
                                          .toLowerCase()
                                          .contains('tomorrow')
                                      ? context.colors.warning
                                      : context.colors.success,
                                ),
                          ),
                        ],
                      ),

                      // Price in Gold
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '\$$rateInt',
                              style: context.textTheme.titleSmall
                                  ?.bold()
                                  .copyWith(color: context.colors.primary),
                            ),
                            TextSpan(
                              text: ' /hr',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.xxs.h,

                  // Name
                  Text(
                    guard.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.bold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                  AppSpacing.xxs.h,

                  // Specialties
                  Text(
                    'Licensed armed, Corporate visits',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontSize: 11)
                        .colour(context.colors.onSurfaceVariant),
                  ),
                  AppSpacing.xs.h,

                  // Stats row: Rating, Reviews, Exp
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: context.colors.primary,
                      ),
                      AppSpacing.xxs.w,
                      Text(
                        guard.rating.toStringAsFixed(2),
                        style: context.textTheme.labelSmall
                            ?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            )
                            .colour(context.colors.onSurface),
                      ),
                      AppSpacing.xs.w,
                      Text(
                        '•',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      AppSpacing.xs.w,
                      Text(
                        '${guard.reviewCount} reviews',
                        style: context.textTheme.labelSmall
                            ?.copyWith(fontSize: 10.5)
                            .colour(context.colors.onSurfaceVariant),
                      ),
                      AppSpacing.xs.w,
                      Text(
                        '•',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      AppSpacing.xs.w,
                      Text(
                        '${guard.experienceYears}+ yrs exp',
                        style: context.textTheme.labelSmall
                            ?.copyWith(fontSize: 10.5)
                            .colour(context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        AppSpacing.sm.h,

        // Full Width Book Now Button
        GestureDetector(
          onTap: onBookNow,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              gradient: context.colors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Book Now',
                  style: context.textTheme.labelMedium?.bold().colour(
                    context.colors.onPrimary,
                  ),
                ),
                AppSpacing.xs.w,
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: context.colors.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
