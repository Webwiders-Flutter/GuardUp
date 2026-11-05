import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '../../data/model/customer_home_data.dart';

/// Company card rendered in the "TOP COMPANY" section of the customer home.
class CustomerCompanyCardWidget extends StatelessWidget {
  final CustomerCompanyItem company;
  final VoidCallback? onBookNow;
  final VoidCallback? onTap;

  const CustomerCompanyCardWidget({
    super.key,
    required this.company,
    this.onBookNow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        w: double.infinity,
        p: AppSpacing.md,
        borderRadius: BorderRadius.circular(24),
        color: context.colors.onPrimary,
        border: Border.all(color: context.colors.borderColor, width: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Initials Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.surfaceDim,
                border: Border.all(
                  color: context.colors.gold.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  company.initials,
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.gold,
                  ),
                ),
              ),
            ),
            AppSpacing.md.w,

            // Company Info Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active Guards Badge & Name
                  Row(
                    children: [
                      QuickContainer(
                        px: 6,
                        py: 4,
                        radius: 30,
                        color: Color(0xFF32353D).withValues(alpha: 0.4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: context.colors.success,
                              size: 8,
                            ),
                            AppSpacing.xxs.w,
                            Text(
                              '${company.activeGuards} Guards Active',
                              style: context.textTheme.bodySmall
                                  ?.copyWith(fontSize: 10)
                                  .colour(context.colors.success),
                            ),
                          ],
                        ),
                      ),

                      Spacer(),
                      QuickContainer(
                        px: 9,
                        py: 2,
                        radius: 4,

                        border: Border.all(
                          color: context.colors.gold.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        color: context.colors.gold.withValues(alpha: 0.1),

                        child: Text(
                          'Book now',
                          style: context.textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              )
                              .colour(context.colors.gold),
                        ),
                      ),
                    ],
                  ),
                  // 02.h,

                  Text(
                    company.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.bold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                  AppSpacing.xxs.h,

                  // Rating, Bookings, Experience
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: context.colors.gold,
                      ),
                      AppSpacing.xxs.w,
                      Text(
                        company.rating.toStringAsFixed(1),
                        style: context.textTheme.bodySmall
                            ?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
                        company.bookingsCount,
                        style: context.textTheme.bodySmall
                            ?.copyWith(fontSize: 11)
                            .colour(
                              context.colors.primary.withValues(alpha: 0.6),
                            ),
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
                        company.experienceYears,
                        style: context.textTheme.bodySmall
                            ?.copyWith(fontSize: 11)
                            .colour(
                              context.colors.primary.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            AppSpacing.sm.w,

            // Book Now Button
          ],
        ),
      ),
    );
  }
}
