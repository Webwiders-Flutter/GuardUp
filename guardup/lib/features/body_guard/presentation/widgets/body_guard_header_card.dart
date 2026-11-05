import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Top profile header card for bodyguard profiles, matching the luxury GuardUp design.
class BodyGuardHeaderCard extends StatelessWidget {
  final String name;
  final String specialization;
  final double rating;
  final String location;
  final num hourlyRate;
  final String avatarAssetPath;
  final bool isVerified;
  final VoidCallback? onTap;

  const BodyGuardHeaderCard({
    super.key,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.location,
    required this.hourlyRate,
    this.avatarAssetPath = '',
    this.isVerified = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAvatar = avatarAssetPath.isNotEmpty
        ? avatarAssetPath
        : Assets.images.profilePicture.path;

    return WrapperCard(
      onTap: onTap,
      padding: AppSpacing.xlg.allPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with Verified Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppImage.asset(
                assetPath: effectiveAvatar,
                width: 22.wPercent(context),
                height: 22.wPercent(context),
                borderRadius: AppRadius.md.toBorderRadius,
                fit: BoxFit.cover,
              ),
              if (isVerified)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: QuickContainer(
                    shape: QuickContainerShape.circle,
                    color: context.colors.surface,
                    p: AppSpacing.xxs,
                    child: QuickContainer(
                      shape: QuickContainerShape.circle,
                      color: context.colors.primary,
                      p: 2.5,
                      child: Icon(
                        Icons.check_rounded,
                        size: AppSizes.iconTiny,
                        color: context.colors.surface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.lg.w,

          // User details (Name, specialization, rating, location)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: context.textTheme.titleMedium?.bold(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.xxs.h,
                Text(
                  specialization,
                  style: context.textTheme.bodySmall?.semiBold().colour(
                    context.colors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.xs.h,
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: AppSizes.iconSm,
                      color: context.colors.primary,
                    ),
                    AppSpacing.xxs.w,
                    Text(
                      rating.toStringAsFixed(1),
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.primary,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        location,
                        style: context.textTheme.labelSmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.xs.w,

          // Pricing block with USD numeric extension
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hourlyRate.toUsd,
                style: context.textTheme.titleLarge?.bold().colour(
                  context.colors.primary,
                ),
              ),
              Text(
                '/ hour',
                style: context.textTheme.labelSmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
