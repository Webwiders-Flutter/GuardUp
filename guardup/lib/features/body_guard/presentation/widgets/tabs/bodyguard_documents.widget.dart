import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '../../../data/model/license_and_badge.model.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Tab content widget displaying verified bodyguard credentials, audited badges,
/// and background verification security clearances.
class BodyguardDocumentsWidget extends StatelessWidget {
  final List<LicenseAndBadgeModel>? licenses;

  const BodyguardDocumentsWidget({super.key, this.licenses});

  @override
  Widget build(BuildContext context) {
    final effectiveLicenses =
        licenses ?? LicenseAndBadgeModel.fakeAuditedLicenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSpacing.lg.h,
        // ---------------------------------------------------------------------
        // Header Row: Title + "4 Audited" Pill Badge
        // ---------------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Verified Licenses & Badges',
                style: context.textTheme.titleMedium?.semiBold(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppSpacing.sm.w,
            QuickContainer(
              radius: AppRadius.full,
              color: context.colors.primary.withValues(alpha: 0.2),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.45),
                width: 1.0,
              ),
              px: AppSpacing.smd,
              py: AppSpacing.sm - 1,
              child: Text(
                '4 Audited',
                style: context.textTheme.labelSmall?.semiBold().colour(
                  context.colors.primary,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.lg.h,

        // ---------------------------------------------------------------------
        // List of License & Badge Cards
        // ---------------------------------------------------------------------
        for (final item in effectiveLicenses) ...[
          _buildLicenseCard(context, item),
          AppSpacing.md.h,
        ],

        // ---------------------------------------------------------------------
        // Background Verification Summary Card
        // ---------------------------------------------------------------------
        _buildBackgroundVerificationCard(context),
        AppSpacing.xl.h,
      ],
    );
  }

  Widget _buildLicenseCard(BuildContext context, LicenseAndBadgeModel item) {
    final icon = item.icon ?? Icons.shield_outlined;

    return WrapperCard(
      padding: AppSpacing.lg.allPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          QuickContainer(
            w: 42,
            h: 42,
            radius: AppRadius.sm,
            color: context.colors.surfaceContainerHigh.withValues(alpha: 0.5),
            border: Border.all(
              color: context.colors.outlineVariant,
              width: 1.0,
            ),
            child: Center(
              child: Icon(
                icon,
                size: AppSizes.iconMd,
                color: context.colors.primary,
              ),
            ),
          ),
          AppSpacing.md.w,

          // Name, Issuer, and Validity Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: context.textTheme.bodyMedium?.semiBold(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.xxs.h,
                if (item.issuingAuthority != null)
                  Text(
                    item.issuingAuthority!,
                    style: context.textTheme.labelSmall?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                AppSpacing.xxs.h,
                Text(
                  item.customValidity ??
                      (item.validTill != null
                          ? item.validTill!.ddMMyyyy
                          : 'Permanent / Lifetime'),
                  style: context.textTheme.labelSmall?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          AppSpacing.xs.w,

          // Verified Pill / Label
          if (item.isVerified)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: AppSizes.iconSm,
                  color: context.colors.primary,
                ),
                AppSpacing.xs.w,
                Text(
                  'Verified',
                  style: context.textTheme.labelSmall?.semiBold().colour(
                    context.colors.primary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundVerificationCard(BuildContext context) {
    return WrapperCard(
      padding: AppSpacing.lg.allPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: AppSizes.iconSm,
                color: context.colors.primary,
              ),
              AppSpacing.sm.w,
              Text(
                'Background Verification',
                style: context.textTheme.bodyMedium?.bold(),
              ),
            ],
          ),
          AppSpacing.md.h,

          // Verification Bullet Points
          _buildVerificationBullet(
            context,
            'Clean criminal record check (RCMP CPIC)',
          ),
          AppSpacing.md.h,
          _buildVerificationBullet(context, 'Biometric identity verified'),
          AppSpacing.md.h,
          _buildVerificationBullet(
            context,
            'Commercial insurance covered (\$2M liability)',
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBullet(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        QuickContainer(
          shape: QuickContainerShape.circle,
          color: context.colors.primary,
          w: 6,
          h: 6,
        ),
        AppSpacing.smd.w,
        Expanded(
          child: Text(
            text,
            style: context.textTheme.labelMedium?.colour(
              context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
