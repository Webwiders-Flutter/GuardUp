import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/models/notification.model.dart';

/// Notification card displaying icon based on [NotificationType], title, body,
/// relative timestamp, unread indicator dot, and trailing navigation chevron inside [WrapperCard].
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationCard({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    return WrapperCard(
      onTap: onTap,
      borderWidth: 1.5,
      padding: AppSpacing.mlg.allPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Notification Type Icon in Rounded QuickContainer
          QuickContainer(
            w: AppSizes.avatarLg,
            h: AppSizes.avatarLg,
            radius: AppRadius.md,
            border: Border.all(
              color: context.colors.outlineVariant,
              width: 1.5,
            ),
            alignment: Alignment.center,
            child: notification.type.svgIcon.svg(
              width: AppSizes.iconMd,
              height: AppSizes.iconMd,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
          AppSpacing.mlg.w,

          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + Timestamp + Unread Dot + Trailing Chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: context.textTheme.titleSmall?.bold().colour(
                          context.colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppSpacing.xs.w,

                    // Timestamp
                    Text(
                      notification.timeAgoFormatted,
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),

                    // Unread Indicator Dot
                    if (!notification.isRead) ...[
                      AppSpacing.sm.w,
                      QuickContainer(
                        w: AppSpacing.ssm,
                        h: AppSpacing.ssm,
                        shape: QuickContainerShape.circle,
                        color: context.colors.primary,
                      ),
                    ],
                  ],
                ),
                AppSpacing.ssm.h,

                // Body text
                Text(
                  notification.body,
                  style: context.textTheme.bodySmall
                      ?.regular()
                      .colour(context.colors.onSurfaceVariant)
                      .lineHeight(1.35),
                ),
              ],
            ),
          ),
          // Chevron Icon
          Icon(
            Icons.chevron_right_rounded,
            size: AppSizes.iconLg,
            color: context.colors.outline,
          ),
        ],
      ),
    );
  }
}
