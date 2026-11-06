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
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/model/transaction.model.dart';

/// Luxury transaction row card matching GuardUp architectural standards.
///
/// Fully uses context color tokens, semantic spacing/padding extensions, and
/// component size constants.
class TransactionCard extends StatelessWidget {
  /// The transaction data to display.
  final TransactionModel transaction;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Whether to render inside a [WrapperCard] container.
  final bool inWrapperCard;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.inWrapperCard = false,
  });

  /// Named constructor configured for dashboard card presentation.
  const TransactionCard.card({super.key, required this.transaction, this.onTap})
    : inWrapperCard = true;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type.isCredit;

    // Use centralized semantic color tokens
    final iconCardBgColor = isCredit
        ? context.colors.successContainer
        : context.colors.errorContainer;

    final iconBgColor = isCredit ? Color(0xFFD8FFDC) : Color(0xFFFFD1E1);

    final iconColor = isCredit ? context.colors.success : context.colors.error;

    if (inWrapperCard) {
      return WrapperCard(
        onTap: onTap,
        padding: AppSpacing.lg.allPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon Circle using QuickContainer
            QuickContainer(
              w: 42,
              h: 42,
              shape: QuickContainerShape.circle,
              color: iconCardBgColor,
              alignment: Alignment.center,
              borderColor: iconCardBgColor,
              child: Icon(
                transaction.type.icon,
                color: iconColor,
                size: AppSizes.iconMd,
              ),
            ),
            AppSpacing.md.w,

            // Content Column (Title & Schedule / Subtitle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    transaction.title,
                    style: context.textTheme.titleSmall?.bold(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.xxs.h,
                  Text(
                    transaction.scheduleText ??
                        '${transaction.formattedDate ?? transaction.dateTime.formattedDateTime} • ${transaction.gateway ?? 'VIP Escort'}',
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppSpacing.sm.w,

            // Amount & Status Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${transaction.type.prefix}${transaction.amount.toUsd}',
                  style: context.textTheme.titleSmall?.bold().colour(iconColor),
                ),
                AppSpacing.xxs.h,
                Text(
                  transaction.status.label,
                  style: context.textTheme.labelSmall?.colour(
                    transaction.status.color(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md.toBorderRadius,
      splashColor: context.colors.primary.withValues(alpha: 0.08),
      highlightColor: context.colors.transparent,
      child: Padding(
        padding: context.horizontalEdgeInsets,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status Icon Circle using QuickContainer & AppSizes
            QuickContainer(
              w: AppSizes.avatarLg,
              h: AppSizes.avatarLg,
              shape: QuickContainerShape.circle,
              color: iconBgColor,
              alignment: Alignment.center,
              child: Icon(
                transaction.type.icon,
                color: iconColor,
                size: AppSizes.iconLg,
              ),
            ),
            AppSpacing.md.w,

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Row with Amount & Description using AppRichText
                  AppRichText(
                    spans: [
                      AppTextSpan(
                        text: '${transaction.amount.toUsd} ',
                        style: context.textTheme.bodyMedium?.semiBold().colour(
                          iconColor,
                        ),
                      ),
                      AppTextSpan(
                        text: transaction.title,
                        style: context.textTheme.bodyMedium?.medium(),
                      ),
                    ],
                  ),
                  AppSpacing.xs.h,

                  // Timestamp Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Assets.svg.calender.svg(
                        width: AppSizes.iconXs,
                        height: AppSizes.iconXs,
                        colorFilter: ColorFilter.mode(
                          context.colors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      AppSpacing.xs.w,
                      Text(
                        transaction.formattedDate ??
                            transaction.dateTime.formattedDateTime,
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceVariant,
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
    );
  }
}
