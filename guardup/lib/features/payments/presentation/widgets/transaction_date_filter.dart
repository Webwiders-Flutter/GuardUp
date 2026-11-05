import 'package:flutter/material.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Filter widget combining "Sort by" text and a [QuickContainer] date dropdown pill.
class TransactionDateFilter extends StatelessWidget {
  /// Current selected sort/filter label. Defaults to localized 'Date'.
  final String? selectedValue;

  /// Optional tap handler for opening the date picker or sort sheet.
  final VoidCallback? onTap;

  const TransactionDateFilter({super.key, this.selectedValue, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // "Sort by" subtle text
        Text(
          context.l10n.sortBy,
          style: context.textTheme.bodySmall?.colour(
            context.colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        AppSpacing.sm.w,

        // QuickContainer Date Pill
        QuickContainer(
          onTap: onTap,
          borderRadius: AppRadius.sm.toBorderRadius,
          radius: AppRadius.sm,
          color: context.colors.onSurface,
          px: AppSpacing.smd,
          py: AppSpacing.xs,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedValue ?? context.l10n.date,
                style: context.textTheme.labelMedium?.semiBold().colour(
                  context.colors.onPrimary,
                ),
              ),
              AppSpacing.xs.w,
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: AppSizes.iconSm,
                color: context.colors.outline,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
