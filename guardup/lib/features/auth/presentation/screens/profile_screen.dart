import '/core/extensions/business_type.extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/company/company.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/bloc/auth_state.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/feedbacks/widgets/app_file_preview.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/features/payments/presentation/screens/membership_plans_screen.dart';
import '../../data/enum/user_role.enum.dart';
import '/features/auth/presentation/screens/account_status_screen.dart';
import '/features/body_guard/presentation/screens/body_guard_profile_screen.dart';
import '/features/auth/presentation/screens/change_password_screen.dart';
import '/features/legal/presentation/screens/contact_us_screen.dart';
import '/features/auth/presentation/screens/edit_profile_screen.dart';
import '/features/legal/presentation/screens/legal_content_screen.dart';
import '/features/auth/presentation/screens/login.screen.dart';
import '/features/payments/presentation/screens/my_bank_details_screen.dart';
import '/features/payments/presentation/screens/my_wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  static const route = '/profile';

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
            fontSize: 16,
            showBackIcon: false,
            alignTitle: .left,
            showNotificationIcon: true,
          ),
          body: SingleChildScrollView(
            padding: context.horizontalEdgeInsets,
            child: Column(
              children: [
                // 1. Dynamic Profile Header Card
                if (role == UserRole.company)
                  _buildCompanyCard(context, state)
                else if (role == UserRole.guard)
                  _buildGuardCard(context, state)
                else
                  _buildCustomerCard(context, state),
                AppSpacing.xl.h,

                // 2. Edit Profile Menu Card
                // if (role != UserRole.guard)
                _ProfileMenuCard(
                  title: context.l10n.editProfile,
                  icon: Icons.person_outline_rounded,
                  onTap: () {
                    context.push(EditProfileScreen.route);
                    // switch (role) {
                    //   case UserRole.customer:
                    //     context.push(EditProfileScreen.route);
                    //     break;
                    //   case UserRole.company:
                    //     context.push(EditProfileScreen.route);
                    //     break;
                    //   default:
                    // }
                  },
                ),
                // 4. Common Settings Menu Cards
                _ProfileMenuCard(
                  title: context.l10n.changePassword,
                  icon: Icons.lock_outline_rounded,
                  onTap: () {
                    context.push(ChangePasswordScreen.route);
                  },
                ),
                // 3. Role-Specific Menu Cards
                if (role == UserRole.guard) ...[
                  _ProfileMenuCard(
                    title: context.l10n.personalInformation.toUpperCase(),
                    icon: Icons.person,
                    onTap: () {
                      context.push(BodyGuardProfileScreen.route);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.myWallet,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      context.push(MyWalletScreen.route);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.myBankDetails,
                    icon: Icons.account_balance_outlined,
                    onTap: () {
                      context.push(MyBankDetailsScreen.route);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.reviewAndRatings,
                    icon: Icons.star_outline_rounded,
                    onTap: () {
                      context.push(BodyGuardProfileScreen.route);
                    },
                  ),
                ] else if (role == UserRole.company) ...[
                  _ProfileMenuCard(
                    title: context.l10n.companyInformation.toUpperCase(),
                    icon: Icons.person_outline_rounded,
                    onTap: () {
                      context.push(CompanyInformationScreen.route);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.myWallet,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () {
                      context.push(MyWalletScreen.route);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.myBank,
                    icon: Icons.account_balance_outlined,
                    onTap: () {
                      context.push(MyBankDetailsScreen.route);
                    },
                  ),
                  _ProfileMenuCard(
                    title: context.l10n.businessDocuments,
                    icon: Icons.folder_shared_outlined,
                    onTap: () {
                      context.push(CompanyDocumentsScreen.route);
                    },
                  ),
                ] else
                  _ProfileMenuCard(
                    title: 'Membership Plan'.toUpperCase(),
                    icon: Icons.card_membership_outlined,
                    onTap: () {
                      context.push(
                        MembershipPlansScreen.route,
                        extra: (
                          mode: MembershipPlanMode.profile,
                          bookingAmount: null,
                          operativeName: null,
                          activePlanId: state.membershipPlanId,
                        ),
                      );
                    },
                  ),

                // _ProfileMenuCard(
                //   title: context.l10n.notifications.toUpperCase(),
                //   icon: Icons.notifications_none_rounded,
                //   onTap: () {
                //     context.push(NotificationsScreen.route);
                //   },
                // ),
                _ProfileMenuCard(
                  title: context.l10n.privacyPolicy,
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    context.push(
                      LegalContentScreen.privacyPolicyRoute,
                      extra: role,
                    );
                  },
                ),
                _ProfileMenuCard(
                  title: context.l10n.termsAndConditions,
                  icon: Icons.gavel_outlined,
                  onTap: () {
                    context.push(LegalContentScreen.termsRoute, extra: role);
                  },
                ),
                _ProfileMenuCard(
                  title: context.l10n.contactUs.toUpperCase(),
                  icon: Icons.support_agent_outlined,
                  onTap: () {
                    context.push(ContactUsScreen.route);
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
                      context.go(LoginScreen.route);
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
                      sl<AuthBloc>().add(const AuthDeleteAccountRequested());
                      context.go(AccountStatusScreen.deletedRoute);
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

  Widget _buildCompanyCard(BuildContext context, AuthState state) {
    final companyName = state.companyName;
    final logoUrl = state.avatarUrl.isNotEmpty ? state.avatarUrl : null;
    final rating = state.rating;
    final companyType = state.companyType.isNotEmpty
        ? state.companyType.businessTypeLabel(context.l10n)
        : 'Licensed Agency';

    final dynamicCompany = CompanyModel(
      id: state.user?.id ?? 'comp_current',
      name: companyName,
      initials: companyName.isNotEmpty ? companyName.getInitials() : 'SP',
      logoUrl: logoUrl,
      rating: rating,
      bio: companyType,
      experienceYears: state.experienceYearsFormatted,
      isVerified: true,
      isOnline: true,
      activeGuards: 0,
      bookingsCount: '0',
    );

    return CompanyCard(
      company: dynamicCompany,
      onTap: () => context.push(CompanyInformationScreen.route),
      onAvatarTap: () {
        final imagePath = logoUrl ?? Assets.images.appLogo.path;
        AppFilePreviewSheet.openInViewer(
          context,
          title: companyName,
          fileUrl: imagePath,
        );
      },
    );
  }

  Widget _buildGuardCard(BuildContext context, AuthState state) {
    final guardName = state.user?.name ?? state.displayName;
    final hourlyRate = state.hourlyRate > 0 ? state.hourlyRate : 45;
    final rating = state.rating;
    final avatar = state.avatarUrl.isNotEmpty
        ? state.avatarUrl
        : Assets.images.dummyAvatar.path;

    final specialization = state.specializationText;
    final location = state.address.isNotEmpty
        ? state.address
        : 'Location not set';

    return _ProfileCard(
      name: guardName.isNotEmpty ? guardName : 'Operative Guard',
      specialization: specialization,
      rating: rating,
      location: location,
      hourlyRate: hourlyRate,
      avatarAssetPath: avatar,
      isVerified: true,
      onTap: () => context.push(BodyGuardProfileScreen.route),
    );
  }

  Widget _buildCustomerCard(BuildContext context, AuthState state) {
    final customerName = state.user?.name ?? state.displayName;
    final email = state.businessEmail;
    final avatar = state.avatarUrl.isNotEmpty
        ? state.avatarUrl
        : Assets.images.dummyAvatar.path;

    return _ProfileCard(
      name: customerName.isNotEmpty ? customerName : '',
      specialization: email.isNotEmpty ? email : '',
      rating: 0.0,
      location: '',
      hourlyRate: 0,
      avatarAssetPath: avatar,
      isVerified: true,
      onTap: () => context.push(EditProfileScreen.route),
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

  void _openImagePreview(BuildContext context) {
    final imagePath = avatarAssetPath.isNotEmpty
        ? avatarAssetPath
        : Assets.images.dummyAvatar.path;

    AppFilePreviewSheet.openInViewer(context, title: name, fileUrl: imagePath);
  }

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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openImagePreview(context),
                child: AppImage.auto(
                  source: avatarAssetPath.isNotEmpty
                      ? avatarAssetPath
                      : Assets.images.dummyAvatar.path,
                  width: 22.wPercent(context),
                  height: 22.wPercent(context),
                  borderRadius: AppRadius.md.toBorderRadius,
                  fit: BoxFit.cover,
                ),
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
                    AppSpacing.sm.w,
                    Text('•', style: context.textTheme.labelSmall),
                    AppSpacing.sm.w,
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
          AppSpacing.sm.w,

          // Right Price & Arrow
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hourlyRate > 0) ...[
                Text(
                  hourlyRate.toUsd,
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.primary,
                  ),
                ),
                Text(
                  '/hr',
                  style: context.textTheme.labelSmall?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
                AppSpacing.xs.h,
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconMd,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Private stateless widget for menu options under the profile card.
class _ProfileMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? textColor;

  const _ProfileMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: WrapperCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppSizes.iconMd,
              color: textColor ?? context.colors.primary,
            ),
            AppSpacing.md.w,
            Expanded(
              child: Text(
                title,
                style: context.textTheme.bodyMedium?.semiBold().colour(
                  textColor ?? context.colors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppSizes.iconMd,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
