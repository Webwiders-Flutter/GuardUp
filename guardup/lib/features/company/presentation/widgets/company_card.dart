import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/model/company.model.dart';
import '/features/customer/presentation/screens/booking_screen.dart';
import '/features/company/presentation/screens/company_details_screen.dart';

/// A luxury security company presentation card rendered across feeds and customer directories.
///
/// Features:
/// - Enclosed in high-end [WrapperCard]
/// - Left avatar circle with gold border, initials / logo, and online presence badge
/// - Active operative headcount pill with green status indicator
/// - Top-right "Book now" action button
/// - Prominent company title
/// - Footer metadata row featuring rating star, booking count, and verified experience
class CompanyCard extends StatelessWidget {
  /// The company domain model containing credentials, operational stats, and rating.
  final CompanyModel company;

  /// Optional callback when the card container is tapped.
  final VoidCallback? onTap;

  /// Optional callback when the avatar is tapped.
  final VoidCallback? onAvatarTap;

  /// Optional callback when the "Book now" action button is tapped.
  final VoidCallback? onBookNow;

  const CompanyCard({
    super.key,
    required this.company,
    this.onTap,
    this.onAvatarTap,
    this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return WrapperCard(
      onTap: onTap ?? () => context.push(CompanyDetailsScreen.route),
      borderRadius: AppRadius.xxl,
      padding: AppSpacing.mlg.allPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // -------------------------------------------------------------------
          // 1. Company Circular Avatar (Gold Ring Border + Initials/Logo + Online Dot)
          // -------------------------------------------------------------------
          _buildAvatar(context),
          AppSpacing.md.w,

          // -------------------------------------------------------------------
          // 2. Company Details & Actions (Status Pill, Book Now, Title, Stats)
          // -------------------------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Active Guards Status Badge & Book Now Action / Checkbox
                _buildTopRow(context),
                AppSpacing.xxs.h,

                // Company Name
                Text(
                  company.name,
                  style: context.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.xxs.h,

                // Bottom Meta: Rating, Total Bookings, Experience
                _buildMetaRow(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUBCOMPONENTS
  // ===========================================================================

  Widget _buildAvatar(BuildContext context) {
    final logoUrl = company.logoUrl;
    final isNetwork = logoUrl != null && logoUrl.startsWith('http');

    final avatarContainer = QuickContainer(
      shape: QuickContainerShape.circle,
      w: 16.wPercent(context),
      h: 16.wPercent(context),
      color: context.colors.surfaceDim,
      border: Border.all(color: context.colors.primary, width: 1.5),
      alignment: Alignment.center,
      child: logoUrl != null
          ? ClipOval(
              child: isNetwork
                  ? AppImage.network(
                      imageUrl: logoUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    )
                  : AppImage.asset(
                      assetPath: logoUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
            )
          : Text(
              company.initials ?? company.name.getInitials(),
              style: context.textTheme.titleMedium?.bold().colour(
                context.colors.primary,
              ),
            ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (onAvatarTap != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAvatarTap,
            child: avatarContainer,
          )
        else
          avatarContainer,
        if (company.isOnline)
          Positioned(
            right: 0,
            bottom: 4,
            child: QuickContainer(
              shape: QuickContainerShape.circle,
              color: context.colors.surface,
              p: 4,
              child: QuickContainer(
                shape: QuickContainerShape.circle,
                color: context.colors.success,
                w: 10,
                h: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      children: [
        // Active Guards Count Pill
        QuickContainer(
          radius: AppRadius.full,
          color: context.colors.success.withValues(alpha: 0.12),
          // border: Border.all(
          //   color: context.colors.success.withValues(alpha: 0.25),
          //   width: 1.0,
          // ),
          px: AppSpacing.sm,
          py: 3.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuickContainer(
                shape: QuickContainerShape.circle,
                color: context.colors.success,
                w: 6,
                h: 6,
              ),
              AppSpacing.xs.w,
              Text(
                '${company.activeGuards} Guards Active',
                style: context.textTheme.labelSmall?.colour(
                  context.colors.success,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        if (onBookNow != null)
          AppButton(
            text: 'Book now',
            isFlexible: true,
            type: ButtonType.secondaryPrimary,
            size: ButtonSize.small,
            height: 23,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            border: BorderSide(
              color: context.colors.primary.withValues(alpha: 0.35),
              width: 0.8,
            ),
            backgroundColor: context.colors.primary.withValues(alpha: 0.08),
            foregroundColor: context.colors.primary,
            borderRadius: AppRadius.sm.toBorderRadius,
            onPressed:
                onBookNow ??
                () => context.push(BookingScreen.route, extra: company),
          ),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          size: AppSizes.iconXs,
          color: context.colors.primary,
        ),
        AppSpacing.xxs.w,
        Text(
          company.rating.toStringAsFixed(1),
          style: context.textTheme.labelSmall,
        ),
        Text(
          '  •  ',
          style: context.textTheme.labelSmall?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
        Text(
          company.bookingsCount,
          style: context.textTheme.labelSmall?.regular().colour(
            context.colors.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
        Text(
          '  •  ',
          style: context.textTheme.labelSmall?.colour(
            context.colors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            company.experienceYears,
            style: context.textTheme.labelSmall?.regular().colour(
              context.colors.primary.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
