import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardup/features/auth/domain/repositories/user_repository.dart';
import 'package:guardup/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import 'package:guardup/shared/widgets/sections/wrapper_card.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';

/// Screen displaying the application status / review stage for onboarding operatives & companies.
class AdminApprovalScreen extends StatefulWidget {
  static const route = '/admin-approval';

  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    final authBloc = sl.isRegistered<AuthBloc>() ? sl<AuthBloc>() : null;
    final currentUserId =
        authBloc?.state.user?.id ??
        (sl.isRegistered<AuthRepository>()
            ? sl<AuthRepository>().currentUserId
            : null);

    if (currentUserId == null || !sl.isRegistered<UserRepository>()) return;

    setState(() => _isChecking = true);

    try {
      final data = await sl<UserRepository>().getUserData(currentUserId);
      if (!mounted) return;

      if (data != null) {
        final rawStatus = (data['status'] as String? ?? '').toUpperCase();

        if (rawStatus == 'APPROVED' || rawStatus == 'ACTIVE') {
          authBloc?.add(const AuthCheckStatusRequested());
          AppSnackbar.success(
            'Your profile has been approved! Welcome to GuardUp.',
          );
          if (mounted) {
            context.go(AppRoutes.home);
          }
          return;
        } else if (rawStatus == 'REJECTED') {
          AppSnackbar.error(
            'Your application was not approved. Please contact support.',
          );
        } else if (rawStatus == 'BLOCKED') {
          AppSnackbar.error('Your account has been suspended.');
        } else {
          AppSnackbar.info(
            'Your application is still under review by our compliance team.',
          );
        }
      } else {
        AppSnackbar.info('Your application is still under review.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(
          'Failed to check status. Please check your connection.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppAppBar.transparent(
        titleWidget: Assets.svg.appBanner.svg(height: AppSizes.iconLg),
        alignTitle: .center,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      AppSpacing.md.h,

                      // Main Application Status Card (NO GLOW, clean border)
                      WrapperCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSpacing.sm.h,
                            // 1. Top Bar: APPLICATION STATUS + Step 2 of 3 Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    QuickContainer(
                                      w: 10,
                                      h: 10,
                                      radius: AppRadius.full,
                                      color: context.colors.primary,
                                    ),
                                    AppSpacing.sm.w,
                                    Text(
                                      context.l10n.applicationStatus,
                                      style: context.textTheme.labelMedium
                                          ?.colour(context.colors.primary)
                                          .textSpacing(1.2),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            AppSpacing.xl.h,

                            // Thin Divider below header row
                            Container(
                              height: 1,
                              color: context.colors.outline.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            AppSpacing.xxl.h,

                            // 2. Application Submitted Title
                            Text(
                              context.l10n.applicationSubmitted,
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleMedium,
                            ),
                            AppSpacing.xxl.h,

                            // 3. Horizontal 3-Step Stepper
                            _buildStepper(context),
                            AppSpacing.xxxl.h,

                            // 4. Under Review Info Box (Rounded-square clock container)
                            WrapperCard(
                              backgroundColor: context.colors.surfaceDim,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  QuickContainer(
                                    w: 32,
                                    h: 32,
                                    radius: AppRadius.md,
                                    color: context.colors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    border: Border.all(
                                      color: context.colors.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1,
                                    ),
                                    alignment: Alignment.center,
                                    child: Assets.svg.clock.svg(
                                      width: AppSizes.iconXs,
                                      height: AppSizes.iconXs,
                                    ),
                                  ),
                                  AppSpacing.md.w,
                                  Expanded(
                                    child: Text(
                                      context.l10n.applicationUnderReviewNotice,
                                      style: context.textTheme.bodySmall
                                          ?.colour(
                                            context.colors.onSurfaceVariant,
                                          )
                                          .lineHeight(1.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      AppSpacing.colossal.h,

                      // 5. Actions (Check Status, Back to Home, & Logout)
                      if (authState.isApproved) ...[
                        AppButton(
                          text: 'Go to Home',
                          trailing: const Icon(
                            Icons.arrow_forward_rounded,
                            size: AppSizes.iconSmd,
                          ),
                          onPressed: () {
                            context.go(AppRoutes.home);
                          },
                        ),
                      ] else ...[
                        AppButton(
                          text: 'Check Status',
                          leading: _isChecking
                              ? const SizedBox(
                                  width: AppSizes.iconSmd,
                                  height: AppSizes.iconSmd,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  size: AppSizes.iconSmd,
                                ),
                          onPressed: _isChecking
                              ? null
                              : _checkStatus,
                        ),
                        AppSpacing.md.h,

                        AppButton(
                          type: ButtonType.text,
                          text: context.l10n.logoutButton,
                          leading: Icon(
                            Icons.logout_rounded,
                            size: AppSizes.iconSmd,
                            color: context.colors.error,
                          ),
                          onPressed: () {
                            sl<AuthBloc>().add(const AuthSignOutRequested());
                            context.go(AppRoutes.login);
                          },
                        ),
                      ],
                      AppSpacing.huge.h,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepper(BuildContext context) {
    const circleSize = 36.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Row of Circles and Connecting Lines
          Row(
            children: [
              // Step 1: Documents (Completed)
              QuickContainer(
                w: circleSize,
                h: circleSize,
                radius: AppRadius.full,
                color: context.colors.primary,
                alignment: Alignment.center,
                child: Icon(
                  Icons.check,
                  size: AppSizes.iconMd,
                  color: context.colors.onPrimary,
                ),
              ),

              // Connecting Line 1-2 (Active Gold)
              Expanded(
                child: Container(height: 2, color: context.colors.primary),
              ),

              // Step 2: Review (Current Active)
              QuickContainer(
                w: circleSize,
                h: circleSize,
                radius: AppRadius.full,
                color: context.colors.surfaceDim,
                border: Border.all(color: context.colors.primary, width: 2),
                alignment: Alignment.center,
                child: QuickContainer(
                  w: 8,
                  h: 8,
                  radius: AppRadius.full,
                  color: context.colors.primary,
                ),
              ),

              // Connecting Line 2-3 (Inactive Outline)
              Expanded(
                child: Container(
                  height: 2,
                  color: context.colors.outline.withValues(alpha: 0.25),
                ),
              ),

              // Step 3: Approval (Upcoming Locked)
              QuickContainer(
                w: circleSize,
                h: circleSize,
                radius: AppRadius.full,
                color: context.colors.surfaceDim,
                border: Border.all(
                  color: context.colors.outline.withValues(alpha: 0.45),
                  width: 2,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_rounded,
                  size: AppSizes.iconSm,
                  color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          AppSpacing.sm.h,

          // Row of Labels Aligned Below Circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  context.l10n.documents,
                  textAlign: TextAlign.start,
                  style: context.textTheme.labelSmall?.colour(
                    context.colors.primary,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  context.l10n.review,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall,
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  context.l10n.approval,
                  textAlign: TextAlign.end,
                  style: context.textTheme.labelSmall?.colour(
                    context.colors.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
