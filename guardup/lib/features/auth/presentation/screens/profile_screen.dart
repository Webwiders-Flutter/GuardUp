import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/notifications/presentation/widgets/notification_icon.widget.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/bloc/auth_state.dart';
import '/features/payments/payments.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/user_role.enum.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      builder: (context, state) {
        final role = state.sessionRole;

        return Scaffold(
          appBar: AppAppBar.transparent(
            title: role.profileTitle(context.l10n),
            alignTitle: .left,
            actions: [NotificationIconWidget(count: 5)],
          ),
          body: SingleChildScrollView(
            padding: context.horizontalEdgeInsets,
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
                  onTap: () {
                    switch (role) {
                      case .company:
                        // context.push(AppRoutes.companyInformation);
                        context.push(AppRoutes.companyDetails);
                      case .guard:
                        context.push(AppRoutes.bodyguardInformation);
                      default:
                    }
                  },
                ),
                AppSpacing.xl.h,

                // 2. Edit Profile Menu Card
                if (role != .guard)
                  _ProfileMenuCard(
                    title: context.l10n.editProfile,
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      switch (role) {
                        case UserRole.customer:
                          context.push(AppRoutes.editProfile);
                          break;
                        case UserRole.company:
                          context.push(AppRoutes.companyEditProfile);
                          break;
                        default:
                      }
                    },
                  ),

                // 3. Role-Specific Menu Cards
                if (role == UserRole.guard) ...[
                  _ProfileMenuCard(
                    title: context.l10n.myWallet,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      context.push(AppRoutes.myWallet);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.myBankDetails,
                    icon: Icons.account_balance_outlined,
                    onTap: () {
                      context.push(AppRoutes.myBankDetails);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.reviewAndRatings,
                    icon: Icons.star_outline_rounded,
                    onTap: () {
                      context.push(AppRoutes.bodyguardInformation);
                    },
                  ),
                ] else if (role == UserRole.company) ...[
                  _ProfileMenuCard(
                    title: context.l10n.myWallet,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      context.push(AppRoutes.myWallet);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.myBank,
                    icon: Icons.account_balance_outlined,
                    onTap: () {
                      context.push(AppRoutes.myBankDetails);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.businessDocuments,
                    icon: Icons.folder_shared_outlined,
                    onTap: () {
                      context.push(AppRoutes.uploadDocuments);
                    },
                  ),
                ],

                // 4. Common Action Cards
                _ProfileMenuCard(
                  title: context.l10n.changePassword,
                  icon: Icons.lock_outline_rounded,
                  onTap: () {
                    context.push(AppRoutes.changePassword);
                  },
                ),
                if (role == .customer)
                  _ProfileMenuCard(
                    title: context.l10n.membershipPlan,
                    icon: Icons.workspace_premium_outlined,
                    onTap: () {
                      context.push(
                        AppRoutes.membershipPlans,
                        extra: (
                          mode: MembershipPlanMode.profile,
                          bookingAmount: 240.0,
                          operativeName: 'Operative Vikram Singh',
                          activePlanId: 'gold_sentinel',
                        ),
                      );
                    },
                  ),
                _ProfileMenuCard(
                  title: context.l10n.privacyPolicy,
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    context.push(AppRoutes.privacyPolicy);
                  },
                ),
                _ProfileMenuCard(
                  title: context.l10n.termsAndConditions,
                  icon: Icons.article_outlined,
                  onTap: () {
                    context.push(AppRoutes.termsAndConditions);
                  },
                ),
                _ProfileMenuCard(
                  title: context.l10n.support,
                  icon: Icons.headset_mic_outlined,
                  onTap: () {
                    context.push(AppRoutes.contactUs);
                  },
                ),
                _ProfileMenuCard(
                  title: context.l10n.logOut.toUpperCase(),
                  textColor: context.colors.error,
                  icon: Icons.logout_rounded,
                  onTap: () async {
                    final result = await AppPopup.showLogoutConfirmation(
                      context,
                    );
                    if (result?.action == PopupAction.confirm &&
                        context.mounted) {
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
                    if (result?.action == PopupAction.confirm &&
                        context.mounted) {
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
      },
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
  final VoidCallback? onTap;

  const _ProfileCard({
    required this.name,
    required this.specialization,
    required this.rating,
    required this.location,
    required this.hourlyRate,
    required this.avatarAssetPath,
    required this.onTap,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    return WrapperCard(
      onTap: onTap,
      padding: AppSpacing.xlg.allPadding,
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
                        size: AppSizes.iconTiny,
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
                  style: context.textTheme.titleMedium?.bold(),
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
                      size: AppSizes.iconSm,
                      color: context.colors.primary,
                    ),
                    AppSpacing.xxs.w,
                    Text(
                      rating.toStringAsFixed(1),
                      style: context.textTheme.labelSmall?.colour(
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
    return WrapperCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor ?? context.colors.onSurfaceVariant,
              size: AppSizes.iconMd,
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
            size: AppSizes.iconLg,
          ),
        ],
      ),
    );
  }
}
