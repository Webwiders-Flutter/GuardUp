import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';

/// Top header widget displaying customer greeting, avatar, verified badge, and notification bell.
class CustomerHeaderWidget extends StatelessWidget {
  final String userName;
  final String subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const CustomerHeaderWidget({
    super.key,
    this.userName = 'Rahul',
    this.subtitle = 'Stay Safe, Always',
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // User Profile Avatar
        GestureDetector(
          onTap: onProfileTap ?? () => context.push(AppRoutes.editProfile),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: AppImage.asset(
                assetPath: Assets.images.profilePicture.path,
                fit: BoxFit.cover,
                width: 48,
                height: 48,
              ),
            ),
          ),
        ),
        AppSpacing.md.w,

        // Greeting & Subtitle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Hello, $userName',
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.onSurface,
                  ),
                ),
                AppSpacing.xs.w,
                Assets.svg.verifiedShieldBadge.svg(
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    context.colors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
            AppSpacing.xxs.h,
            Text(
              subtitle,
              style: context.textTheme.bodySmall?.regular().colour(
                context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
