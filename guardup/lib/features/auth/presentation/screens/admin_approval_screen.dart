import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/shared/widgets/sections/wrapper_card.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
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
class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        titleWidget: Assets.svg.appBanner.svg(height: 24),
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
                            // 1. Top Bar: APPLICATION STATUS + Step 2 of 3 Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    QuickContainer(
                                      w: 8,
                                      h: 8,
                                      radius: AppRadius.full,
                                      color: context.colors.primary,
                                    ),
                                    AppSpacing.xs.w,
                                    Text(
                                      context.l10n.applicationStatus,
                                      style: context.textTheme.labelMedium
                                          ?.bold()
                                          .colour(context.colors.primary)
                                          .textSpacing(1.2),
                                    ),
                                  ],
                                ),
                                // QuickContainer(
                                //   px: AppSpacing.sm,
                                //   py: AppSpacing.xs,
                                //   radius: AppRadius.round,
                                //   color: context.colors.surfaceDim,
                                //   border: Border.all(
                                //     color: context.colors.outlineVariant
                                //         .withValues(alpha: 0.35),
                                //     width: 1,
                                //   ),
                                //   child: Text(
                                //     context.l10n.step2Of3,
                                //     style: context.textTheme.labelSmall
                                //         ?.medium()
                                //         .colour(
                                //           context.colors.onSurfaceVariant,
                                //         ),
                                //   ),
                                // ),
                              ],
                            ),
                            AppSpacing.lg.h,

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
                              style: context.textTheme.titleMedium?.colour(
                                context.colors.onSurface,
                              ),
                            ),
                            AppSpacing.xxl.h,

                            // 3. Horizontal 3-Step Stepper
                            _buildStepper(context),
                            AppSpacing.xxxl.h,

                            // 4. Under Review Info Box (Rounded-square clock container)
                            WrapperCard(
                              padding: AppSpacing.md.allPadding,
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
                                      width: 15,
                                      height: 15,
                                    ),
                                  ),
                                  AppSpacing.md.w,
                                  Expanded(
                                    child: Text(
                                      context.l10n.applicationUnderReviewNotice,
                                      style: context.textTheme.bodySmall
                                          ?.regular()
                                          .colour(
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

                      // 5. Logout Button
                      AppButton(
                        text: context.l10n.checkStatus,
                        size: ButtonSize.large,
                        onPressed: () {
                          context.go(AppRoutes.home);
                        },
                      ),
                      AppSpacing.lg.h,
                      AppButton(
                        type: .secondaryPrimary,
                        text: context.l10n.logoutButton,
                        size: ButtonSize.large,
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            const AuthSignOutRequested(),
                          );
                          context.go(AppRoutes.login);
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
                  size: 20,
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
                  size: 16,
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
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.bold().colour(
                    context.colors.primary,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  context.l10n.review,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelSmall?.bold().colour(
                    context.colors.onSurface,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  context.l10n.approval,
                  textAlign: TextAlign.center,
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
