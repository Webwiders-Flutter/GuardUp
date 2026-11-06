import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/models/conversation.model.dart';

/// Luxury conversation card for chat overview screen matching GuardUp design standards.
///
/// Features an operative avatar thumbnail, verified badge, read receipts,
/// and message preview inside a [WrapperCard].
class ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback? onTap;

  const ConversationCard({super.key, required this.conversation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    final isMe = lastMessage?.isMe ?? false;
    final isRead = lastMessage?.status.isRead ?? false;

    return WrapperCard(
      onTap: onTap,
      borderColor: context.colors.transparent,
      padding: AppSpacing.lg.allPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Operative Avatar (Rounded Square)
          ClipRRect(
            borderRadius: AppRadius.md.toBorderRadius,
            child: conversation.avatarUrl != null
                ? Image.asset(
                    conversation.avatarUrl!,
                    width: AppSizes.avatarLg,
                    height: AppSizes.avatarLg,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    Assets.images.profilePicture.path,
                    width: AppSizes.avatarLg,
                    height: AppSizes.avatarLg,
                    fit: BoxFit.cover,
                  ),
          ),
          AppSpacing.md.w,

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + Verified badge + Timestamp
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        conversation.title,
                        style: context.textTheme.titleSmall?.bold(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (conversation.isVerified) ...[
                      AppSpacing.xs.w,
                      Icon(
                        Icons.verified_rounded,
                        size: AppSizes.iconXs,
                        color: context.colors.primary,
                      ),
                    ],
                    AppSpacing.sm.w,
                    const Spacer(),

                    // Timestamp
                    Text(
                      conversation.customFormattedTime ??
                          (conversation.updatedAt.isToday
                              ? conversation.updatedAt.chatTime
                              : conversation.updatedAt.shortDate),
                      style: context.textTheme.labelSmall?.colour(
                        conversation.updatedAt.isToday
                            ? context.colors.primary
                            : context.colors.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.xs.h,

                // Message status + Preview Snippet
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isMe) ...[
                      Icon(
                        Icons.done_all_rounded,
                        size: AppSizes.iconSm,
                        color: isRead
                            ? context.colors.success
                            : context.colors.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                      ),
                      AppSpacing.xs.w,
                    ],
                    Expanded(
                      child: Text(
                        conversation.lastMessage?.content ?? '',
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceTertiary,
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
        ],
      ),
    );
  }
}
