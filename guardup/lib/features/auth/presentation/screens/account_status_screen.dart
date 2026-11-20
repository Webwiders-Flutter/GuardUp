import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '/features/legal/presentation/screens/contact_us_screen.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/features/customer/presentation/screens/customer_home_screen.dart';
import '/features/body_guard/presentation/screens/body_guard_complete_profile_screen.dart';
import '/features/company/presentation/screens/company_complete_profile_screen.dart';

/// Screen displayed when a user account has been blocked or soft-deleted by an administrator.
class AccountStatusScreen extends StatelessWidget {
  static const blockedRoute = '/account-blocked';
  static const deletedRoute = '/account-deleted';

  final bool isDeleted;

  const AccountStatusScreen({super.key, this.isDeleted = false});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAccountDeleted =
        isDeleted || authState.status == UserStatus.deleted;

    final badgeText = isAccountDeleted
        ? 'ACCOUNT DEACTIVATED'
        : 'ACCOUNT SUSPENDED';
    final badgeColor = isAccountDeleted
        ? context.colors.error
        : context.colors.error;

    final titleText = isAccountDeleted
        ? 'Account Deleted'
        : 'Account Suspended';
    final descriptionText = isAccountDeleted
        ? 'Your account has been deleted. All operational privileges, memberships, and records have been terminated.'
        : 'Your account access has been suspended by an administrator due to security compliance or terms of service violations.';

    final iconData = isAccountDeleted
        ? Icons.delete_forever_rounded
        : Icons.block_flipped;

    final userIdentifier =
        authState.email ?? authState.user?.name ?? authState.user?.id ?? 'User';

    return Scaffold(
      appBar: AppAppBar.transparent(
        titleWidget: Assets.svg.appBanner.svg(height: AppSizes.iconLg),
        alignTitle: .center,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.isBlocked != current.isBlocked ||
            previous.isDeleted != current.isDeleted,
        listener: (context, state) {
          if (!state.isBlocked && !isAccountDeleted) {
            AppSnackbar.success('Your account access has been restored.');
            if (state.isPendingApproval || state.isRejected) {
              context.go(AdminApprovalScreen.route);
            } else if (state.requiresOnboarding) {
              if (state.isGuard) {
                context.go(BodyGuardCompleteProfileScreen.route);
              } else if (state.isCompany) {
                context.go(CompanyCompleteProfileScreen.route);
              }
            } else {
              context.go(CustomerHomeScreen.route);
            }
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: context.horizontalEdgeInsets,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        AppSpacing.lg.h,

                        // Main Status Card
                        WrapperCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppSpacing.sm.h,

                              // 1. Status Indicator Tag
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  QuickContainer(
                                    w: 10,
                                    h: 10,
                                    radius: AppRadius.full,
                                    color: badgeColor,
                                  ),
                                  AppSpacing.sm.w,
                                  Text(
                                    badgeText,
                                    style: context.textTheme.labelMedium
                                        ?.bold()
                                        .colour(badgeColor)
                                        .textSpacing(1.2),
                                  ),
                                ],
                              ),
                              AppSpacing.xxl.h,

                              // 2. Large Semantic Icon Container
                              Center(
                                child: QuickContainer(
                                  w: 88,
                                  h: 88,
                                  radius: AppRadius.full,
                                  color: context.colors.error.withValues(
                                    alpha: 0.12,
                                  ),
                                  border: Border.all(
                                    color: context.colors.error.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 1.5,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    iconData,
                                    size: 44,
                                    color: context.colors.error,
                                  ),
                                ),
                              ),
                              AppSpacing.xxl.h,

                              // 3. Title
                              Text(
                                titleText,
                                textAlign: TextAlign.center,
                                style: context.textTheme.titleMedium
                                    ?.semiBold(),
                              ),
                              AppSpacing.md.h,

                              // 4. Description
                              Text(
                                descriptionText,
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium
                                    ?.colour(context.colors.onSurfaceVariant)
                                    .lineHeight(1.5),
                              ),
                              AppSpacing.xxl.h,

                              // 5. Account Details Box
                              if (userIdentifier != 'User') ...[
                                QuickContainer(
                                  p: AppSpacing.md,
                                  radius: AppRadius.sm,
                                  color: context.colors.surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  border: Border.all(
                                    color: context.colors.outlineVariant
                                        .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: AppSizes.iconSm,
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                      AppSpacing.sm.w,
                                      Expanded(
                                        child: Text(
                                          'Account: $userIdentifier',
                                          style: context.textTheme.bodySmall
                                              ?.colour(
                                                context.colors.onSurfaceVariant,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.md.h,
                              ],
                            ],
                          ),
                        ),

                        const Spacer(),
                        AppSpacing.xl.h,

                        // 6. Action Buttons
                        AppButton(
                          type: ButtonType.secondaryOff,
                          text: 'Contact Support',
                          leading: const Icon(
                            Icons.mail_outline_rounded,
                            size: AppSizes.iconSmd,
                          ),
                          onPressed: () {
                            context.push(ContactUsScreen.route);
                          },
                        ),
                        AppSpacing.md.h,

                        AppButton(
                          text: 'Back to Login',
                          leading: const Icon(
                            Icons.logout_rounded,
                            size: AppSizes.iconSmd,
                          ),
                          onPressed: () {
                            sl<AuthBloc>().add(const AuthSignOutRequested());
                            context.go(LoginScreen.route);
                          },
                        ),
                        AppSpacing.huge.h,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
