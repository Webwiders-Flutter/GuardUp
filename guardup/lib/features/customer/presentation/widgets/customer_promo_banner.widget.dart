import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';

/// Luxury promo banner showcasing GuardUp Elite / VIP Protection services.
class CustomerPromoBannerWidget extends StatelessWidget {
  final String badgeText;
  final String title;
  final String? description;
  final String buttonText;
  final VoidCallback? onBookNow;
  final bool isCompact;

  const CustomerPromoBannerWidget({
    super.key,
    this.badgeText = 'GUARDUP ELITE',
    this.title = 'Premium Security\nFor Every Occasion',
    this.description =
        'Armed & executive protection operatives ready for immediate...',
    this.buttonText = 'Book Now',
    this.onBookNow,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return QuickContainer(
      w: double.infinity,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      gradient: LinearGradient(
        colors: [
          Color(0xFF1A202D).withValues(alpha: 0.85),
          Color(0xFF0F131C).withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: context.colors.primary.withValues(alpha: 0.25),
        width: 1,
      ),
      pt: 16,
      pl: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Column: Texts and Button
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: context.colors.gold.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: context.colors.gold,
                      ),
                      AppSpacing.xxs.w,
                      Text(
                        badgeText,
                        style: context.textTheme.labelSmall
                            ?.copyWith(
                              fontSize: 9.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w400,
                            )
                            .colour(context.colors.gold),
                      ),
                    ],
                  ),
                ),
                AppSpacing.xs.h,

                // Title
                Text(
                  title,
                  style:
                      (isCompact
                              ? context.textTheme.titleSmall
                              : context.textTheme.titleMedium)
                          ?.colour(context.colors.onSurface),
                ),

                if (description != null && !isCompact) ...[
                  AppSpacing.xxs.h,
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall
                        ?.copyWith(fontSize: 11)
                        .colour(context.colors.onSurfaceVariant),
                  ),
                ],
                AppSpacing.sm.h,

                // Book Now Button
                GestureDetector(
                  onTap: onBookNow,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          buttonText,
                          style: context.textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              )
                              .colour(context.colors.onPrimary),
                        ),
                        AppSpacing.xxs.w,
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: context.colors.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                20.h,
              ],
            ),
          ),

          AppSpacing.sm.w,

          // Right: Bodyguard Photo
          Expanded(
            flex: 2,
            child: AppImage.asset(
              height: 140,
              assetPath: Assets.images.profilePicture2.path,
              fit: BoxFit.cover,
            ),
          ),
          08.w,
        ],
      ),
    );
  }
}
