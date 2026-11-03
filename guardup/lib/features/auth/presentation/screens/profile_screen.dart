import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/di/injection_container.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/payments/payments.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: context.l10n.customerProfile,
        centerTitle: false,
        actions: [
          QuickContainer(
            w: 38,
            h: 38,
            shape: QuickContainerShape.circle,
            color: context.colors.surfaceContainer.withValues(alpha: 0.85),
            border: Border.all(color: context.colors.outlineVariant, width: 1),
            alignment: Alignment.center,
            mr: AppSpacing.lg,
            child: Assets.svg.profileCircle.svg(
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.screenPadding,
        child: Column(
          children: [
            // 1. Profile Header Card
            _ProfileCard(
              name: 'Michael Carter',
              specialization: 'Licensed armed, Corporate visits',
              rating: 4.8,
              location: 'Toronto, ON',
              hourlyRate: 60,
              avatarAssetPath: Assets.images.profilePicture.path,
              isVerified: true,
            ),
            AppSpacing.xl.h,

            // 2. Menu Action Cards
            _ProfileMenuCard(
              title: context.l10n.editProfile,
              onTap: () {
                context.push(AppRoutes.editProfile);
              },
            ),
            _ProfileMenuCard(
              title: context.l10n.changePassword,
              onTap: () {
                context.push(AppRoutes.changePassword);
              },
            ),
            _ProfileMenuCard(
              title: context.l10n.membershipPlan,
              onTap: () {
                context.push(
                  AppRoutes.membershipPlans,
                  extra: (
                    mode: MembershipPlanMode.booking,
                    bookingAmount: 240.0,
                    operativeName: 'Operative Vikram Singh',
                    activePlanId: 'gold_sentinel',
                  ),
                );
              },
            ),
            _ProfileMenuCard(
              title: context.l10n.privacyPolicy,
              onTap: () {
                context.push(AppRoutes.privacyPolicy);
              },
            ),
            _ProfileMenuCard(
              title: context.l10n.termsAndConditions,
              onTap: () {
                context.push(AppRoutes.termsAndConditions);
              },
            ),
            _ProfileMenuCard(
              title: context.l10n.support,
              onTap: () {
                context.push(AppRoutes.contactUs);
              },
            ),
            _ProfileMenuCard(
              title: context.l10n.logOut.toUpperCase(),
              textColor: context.colors.error,
              icon: Icons.logout_rounded,
              onTap: () async {
                final result = await AppPopup.showLogoutConfirmation(context);
                if (result?.action == PopupAction.confirm && context.mounted) {
                  sl<AuthBloc>().add(const AuthSignOutRequested());
                  context.go(AppRoutes.login);
                }
              },
            ),
            _ProfileMenuCard(
              title: context.l10n.deleteAccount,
              textColor: context.colors.error,
              icon: Icons.delete_forever_rounded,
              onTap: () async {
                final result = await AppPopup.showDeleteAccountConfirmation(
                  context,
                );
                if (result?.action == PopupAction.confirm && context.mounted) {
                  sl<AuthBloc>().add(const AuthSignOutRequested());
                  context.go(AppRoutes.login);
                }
              },
            ),
            AppSpacing.xxl.h,
          ],
        ),
      ),
    );
  }
}

/// Private stateless widget for the primary profile information card.
class _ProfileCard extends StatelessWidget {
  final String name;
  final String specialization;
  final double rating;
  final String location;
  final num hourlyRate;
  final String avatarAssetPath;
  final bool isVerified;

  const _ProfileCard({
    required this.name,
    required this.specialization,
    required this.rating,
    required this.location,
    required this.hourlyRate,
    required this.avatarAssetPath,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    return QuickContainer(
      p: AppSpacing.xlg,
      color: context.colors.onPrimary,
      radius: AppRadius.lg,
      border: Border.all(color: context.colors.outlineVariant, width: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with Verified Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppImage.asset(
                assetPath: avatarAssetPath,
                width: 22.wPercent(context),
                height: 22.wPercent(context),
                borderRadius: AppRadius.md.toBorderRadius,
                fit: BoxFit.cover,
              ),
              if (isVerified)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: QuickContainer(
                    shape: QuickContainerShape.circle,
                    color: context.colors.surface,
                    p: AppSpacing.xxs,
                    child: QuickContainer(
                      shape: QuickContainerShape.circle,
                      color: context.colors.primary,
                      p: 2.5,
                      child: Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: context.colors.surface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.lg.w,

          // User details (Name, specialization, rating, location)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.xxs.h,
                Text(
                  specialization,
                  style: context.textTheme.bodySmall?.semiBold().colour(
                    context.colors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.xs.h,
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: context.colors.primary,
                    ),
                    AppSpacing.xxs.w,
                    Text(
                      rating.toStringAsFixed(1),
                      style: context.textTheme.labelSmall?.bold().colour(
                        context.colors.primary,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        location,
                        style: context.textTheme.labelSmall?.colour(
                          context.colors.onSurfaceVariant,
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
          AppSpacing.xs.w,

          // Pricing block with USD numeric extension
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hourlyRate.toUsd,
                style: context.textTheme.titleLarge?.bold().colour(
                  context.colors.primary,
                ),
              ),
              Text(
                '/ hour',
                style: context.textTheme.labelSmall?.colour(
                  context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Private stateless widget for menu options below the profile card.
class _ProfileMenuCard extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Color? textColor;
  final IconData? icon;

  const _ProfileMenuCard({
    required this.title,
    this.onTap,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return QuickContainer(
      mb: AppSpacing.lg,
      px: AppSpacing.lg,
      py: AppSpacing.xl,
      color: context.colors.surfaceContainer.withValues(alpha: 0.72),
      radius: AppRadius.lg,
      border: Border.all(color: context.colors.outlineVariant, width: 1),
      onTap: onTap,
      ripple: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor ?? context.colors.onSurfaceVariant,
              size: 20,
            ),
            AppSpacing.md.w,
          ],
          Expanded(
            child: Text(
              title,
              style: context.textTheme.labelLarge
                  ?.colour(textColor ?? context.colors.onSurface)
                  .textSpacing(0.6),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: textColor ?? context.colors.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }
}
