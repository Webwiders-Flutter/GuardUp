import 'package:flutter/material.dart';
import 'package:guardup/features/company/data/model/company.model.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';

/// Bodyguard card supporting both the home spotlight view and the full listing view.
class CustomerBodyguardCardWidget extends StatelessWidget {
  final CompanyModel item;
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
    final guard = item;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: double.infinity,
        p: AppSpacing.md,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: context.colors.onPrimary,

        border: Border.all(
          color: context.colors.borderColor.withValues(alpha: 0.5),
          width: 1,
        ),
        child: _buildListCard(context, guard, 4),
      ),
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
            Stack(
              alignment: .bottomRight,
              children: [
                QuickContainer(
                  mr: 8,
                  mb: 8,
                  w: 80,
                  h: 95,
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.4),
                  ),
                  radius: 16,
                  clipBehavior: .hardEdge,
                  p: 1,
                  child: AppImage.asset(
                    assetPath:
                        guard.user.profileImageUrl ??
                        Assets.images.profilePicture.path,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                AppImage.svgAsset(
                  assetPath: Assets.svg.verifiedBadge.path,

                  width: 30,
                ),
              ],
            ),
            AppSpacing.ssm.w,

            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSpacing.xs.h,
                  // Status & Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Availability Status Badge
                      QuickContainer(
                        px: 8,
                        py: 2.5,
                        radius: 30,
                        border: Border.all(
                          color: context.colors.success.withValues(alpha: 0.6),

                          width: 0.5,
                        ),
                        color: context.colors.success.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: context.colors.success,
                            ),
                            AppSpacing.xs.w,
                            Text(
                              '12 Guards Active',
                              style: context.textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  )
                                  .colour(context.colors.success),
                            ),
                          ],
                        ),
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
                                color: context.colors.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.xs.h,

                  // Name
                  Text(
                    guard.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.bold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                  AppSpacing.xs.h,

                  // Specialties
                  Text(
                    'Licensed armed, Corporate visits',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontSize: 11)
                        .colour(context.colors.primary),
                  ),
                  AppSpacing.sm.h,

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
                      AppSpacing.sm.w,
                      Text(
                        '•',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                      AppSpacing.sm.w,
                      Text(
                        '${guard.reviewCount} reviews',
                        style: context.textTheme.labelSmall
                            ?.copyWith(fontSize: 10.5)
                            .colour(context.colors.onSurfaceVariant),
                      ),
                      AppSpacing.sm.w,
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

        Divider(color: context.colors.borderColor, height: 10),
        06.h,

        GestureDetector(
          onTap: onBookNow,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 13),
            decoration: BoxDecoration(
              gradient: context.colors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
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
              mainAxisSize: .min,
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
