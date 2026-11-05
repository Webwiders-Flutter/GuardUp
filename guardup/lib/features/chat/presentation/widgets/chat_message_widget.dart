import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '../../data/models/message.model.dart';

/// Reusable chat message bubble widget displaying outgoing gold bubbles or
/// incoming dark bubbles with operative avatar, rich text highlights, vehicle badge,
/// timestamp, and delivery receipts.
class ChatMessageWidget extends StatelessWidget {
  final MessageModel message;
  final String? senderAvatarUrl;
  final VoidCallback? onVehicleBadgeTap;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.senderAvatarUrl,
    this.onVehicleBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isMe) {
      return _buildOutgoingMessage(context);
    }
    return _buildIncomingMessage(context);
  }

  Widget _buildOutgoingMessage(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outgoing Gold Luxury Bubble
          QuickContainer(
            color: context.colors.primary,
            // radius: AppRadius.lg,
            radiusBR: message.isMe ? 0 : AppRadius.lg,
            radiusBL: AppRadius.lg,
            radiusTL: AppRadius.lg,
            radiusTR: AppRadius.lg,

            maxW: 75.wPercent(context),
            p: AppSpacing.md,
            child: Text(
              message.content,
              style: context.textTheme.bodyMedium?.medium().colour(
                context.colors.onPrimary,
              ),
            ),
          ),
          AppSpacing.xs.h,

          // Metadata row (Time + Double Checkmark)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.customFormattedTime ?? message.createdAt.chatTime,
                style: context.textTheme.labelSmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
              AppSpacing.xs.w,
              Icon(
                Icons.done_all_rounded,
                size: AppSizes.iconXs,
                color: context.colors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingMessage(BuildContext context) {
    final avatar = senderAvatarUrl ?? Assets.images.profilePicture2.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Operative Circular Avatar aligned to bottom of bubble
            ClipRRect(
              borderRadius: AppRadius.full.toBorderRadius,
              child: Image.asset(
                avatar,
                width: AppSizes.avatarSm,
                height: AppSizes.avatarSm,
                fit: BoxFit.cover,
              ),
            ),
            AppSpacing.sm.w,

            // Incoming Dark Bubble
            Flexible(
              child: QuickContainer(
                color: context.colors.surfaceContainer,
                border: Border.all(
                  color: context.colors.outlineVariant.withValues(alpha: 0.35),
                  width: 1,
                ),
                radiusBL: !message.isMe ? 0 : AppRadius.lg,
                radiusBR: AppRadius.lg,
                radiusTL: AppRadius.lg,
                radiusTR: AppRadius.lg,
                maxW: 75.wPercent(context),
                p: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text with potential highlighted text (e.g. License plate)
                    if (message.highlightedText != null)
                      AppRichText(
                        spans: [
                          AppTextSpan(
                            text: message.content,
                            style: context.textTheme.bodySmall?.increaseSize(1),
                          ),
                          AppTextSpan(
                            text: message.highlightedText!,
                            style: context.textTheme.bodySmall
                                ?.bold()
                                .colour(context.colors.primary)
                                .increaseSize(1),
                          ),
                        ],
                      )
                    else
                      Text(
                        message.content,
                        style: context.textTheme.bodySmall?.increaseSize(1),
                      ),

                    // Optional Vehicle Identification Badge
                    if (message.vehicleBadge != null) ...[
                      AppSpacing.sm.h,
                      InkWell(
                        onTap: onVehicleBadgeTap,
                        borderRadius: AppRadius.sm.toBorderRadius,
                        child: QuickContainer(
                          radius: AppRadius.sm,
                          color: context.colors.surfaceDim.withValues(
                            alpha: 0.7,
                          ),
                          border: Border.all(
                            color: context.colors.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                            width: 1,
                          ),
                          px: AppSpacing.sm,
                          py: AppSpacing.xs,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.directions_car_rounded,
                                size: AppSizes.iconSm,
                                color: context.colors.primary,
                              ),
                              AppSpacing.xs.w,
                              Flexible(
                                child: Text(
                                  message.vehicleBadge!,
                                  style: context.textTheme.labelSmall
                                      ?.medium()
                                      .colour(context.colors.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        AppSpacing.xs.h,

        // Timestamp indented below the bubble
        Padding(
          padding: EdgeInsets.only(left: AppSizes.avatarSm + AppSpacing.sm),
          child: Text(
            message.customFormattedTime ?? message.createdAt.chatTime,
            style: context.textTheme.labelSmall?.colour(
              context.colors.onSurfaceTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill widget separating messages by date / time interval (e.g. "TODAY, 9:40 AM").
class ChatDateChip extends StatelessWidget {
  final String dateText;

  const ChatDateChip({super.key, required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: QuickContainer(
        radius: AppRadius.full,
        color: context.colors.surfaceContainerHigh.withValues(alpha: 0.6),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
        px: AppSpacing.md,
        py: AppSpacing.xs,
        child: Text(
          dateText,
          style: context.textTheme.labelSmall?.bold().colour(
            context.colors.onSurfaceTertiary,
          ),
        ),
      ),
    );
  }
}
