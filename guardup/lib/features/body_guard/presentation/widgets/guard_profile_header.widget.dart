import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';

/// Top hero card featuring operative photo, verified officer badge, name,
/// specialization, and hourly rate.
class GuardProfileHeaderWidget extends StatelessWidget {
  final String name;
  final String specialization;
  final double hourlyRate;
  final String imagePath;
  final bool isVerified;
  final VoidCallback? onImageTap;

  const GuardProfileHeaderWidget({
    super.key,
    this.name = 'Vikram Singh',
    this.specialization = 'Licensed armed, Corporate visits',
    this.hourlyRate = 60.0,
    required this.imagePath,
    this.isVerified = true,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final rateInt = hourlyRate.toInt();
    final isNetwork = imagePath.startsWith('http');

    return QuickContainer(
      w: double.infinity,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      color: context.colors.surfaceContainer,
      border: Border.all(
        color: context.colors.primary.withValues(alpha: 0.3),
        width: 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operative Photo with Top-Right Verified Badge
          GestureDetector(
            onTap: onImageTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadius.lg),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 190,
                    child: isNetwork
                        ? AppImage.network(
                            imageUrl: imagePath,
                            fit: BoxFit.cover,
                          )
                        : AppImage.asset(
                            assetPath: imagePath.isNotEmpty
                                ? imagePath
                                : Assets.images.profilePicture.path,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                // Gradient fade overlay at bottom of photo
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          context.colors.surfaceContainer.withValues(alpha: 0.2),
                          context.colors.surfaceContainer.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Verified Officer Badge
                if (isVerified)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceDim.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: context.colors.primary.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: context.colors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          AppSpacing.xs.w,
                          Text(
                            'VERIFIED OFFICER',
                            style: context.textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 9.5,
                                  letterSpacing: 0.8,
                                )
                                .colour(context.colors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Operative Name, Specialization, and Rate
                Positioned(
                  bottom: 10,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: context.textTheme.titleMedium
                                        ?.bold()
                                        .colour(context.colors.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified) ...[
                                  AppSpacing.xs.w,
                                  Assets.svg.verifiedBadge.svg(
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                              ],
                            ),
                            AppSpacing.xxs.h,
                            Text(
                              specialization,
                              style: context.textTheme.bodySmall
                                  ?.copyWith(fontSize: 10)
                                  .colour(context.colors.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Hourly Rate Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rate',
                            style: context.textTheme.labelSmall
                                ?.copyWith(fontSize: 10)
                                .colour(
                                  context.colors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '\$$rateInt',
                                  style: context.textTheme.titleMedium
                                      ?.bold()
                                      .colour(context.colors.primary),
                                ),
                                TextSpan(
                                  text: ' /hr',
                                  style: context.textTheme.labelSmall
                                      ?.copyWith(fontSize: 10)
                                      .colour(
                                        context.colors.onSurfaceVariant
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
