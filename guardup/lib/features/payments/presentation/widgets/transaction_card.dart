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
import '/shared/widgets/misc/app_rich_text.dart';
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

  const TransactionCard({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type.isCredit;

    // Use centralized semantic color tokens
    final iconBgColor = isCredit
        ? context.colors.successContainer
        : context.colors.errorContainer;

    final iconColor = isCredit ? context.colors.success : context.colors.error;

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
                        text: '${transaction.amountFormatted} ',
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
                        transaction.displayDate,
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
