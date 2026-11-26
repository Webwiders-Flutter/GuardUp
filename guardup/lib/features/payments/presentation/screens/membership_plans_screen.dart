import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/customer/presentation/screens/customer_home_screen.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../bloc/membership_plans/membership_plans_bloc.dart';
import '../widgets/plan_selection_card.dart';

/// The invocation mode defining header text, badges, and bottom action buttons.
enum MembershipPlanMode {
  /// Invoked during booking / checkout to apply instant discounts.
  @JsonValue('BOOKING')
  booking('BOOKING'),

  /// Invoked from Profile -> Membership Plan to view or upgrade membership.
  @JsonValue('PROFILE')
  profile('PROFILE'),

  /// Invoked right after customer signup & OTP verification to select membership plan.
  @JsonValue('ONBOARDING')
  onboarding('ONBOARDING');

  final String apiValue;

  const MembershipPlanMode(this.apiValue);
}

/// Named record typedef for navigation arguments to [MembershipPlansScreen].
typedef MembershipPlanArgs = ({
  MembershipPlanMode? mode,
  double? bookingAmount,
  String? operativeName,
  String? activePlanId,
});

class MembershipPlansScreen extends StatelessWidget {
  static const route = '/membership-plans';

  final MembershipPlanMode mode;
  final double? bookingAmount;
  final String? operativeName;
  final String? activePlanId;

  const MembershipPlansScreen({
    super.key,
    this.mode = MembershipPlanMode.profile,
    this.bookingAmount = 240.0,
    this.operativeName = 'Operative Vikram Singh',
    this.activePlanId,
  });

  @override
  Widget build(BuildContext context) {
    final authPlanId = context.read<AuthBloc>().state.membershipPlanId;
    final resolvedActivePlanId =
        (activePlanId != null && activePlanId!.isNotEmpty)
            ? activePlanId
            : (authPlanId != null && authPlanId.isNotEmpty
                ? authPlanId
                : null);

    return BlocProvider(
      create: (_) => sl<MembershipPlansBloc>()
        ..add(MembershipPlansStarted(activePlanId: resolvedActivePlanId)),
      child: _MembershipPlansView(
        mode: mode,
        bookingAmount: bookingAmount,
        operativeName: operativeName,
      ),
    );
  }
}

class _MembershipPlansView extends StatelessWidget {
  final MembershipPlanMode mode;
  final double? bookingAmount;
  final String? operativeName;

  const _MembershipPlansView({
    required this.mode,
    this.bookingAmount,
    this.operativeName,
  });

  void _handleAction() {
    // TODO(migration): membership purchase not implemented (no column)
    AppSnackbar.info('Coming Soon! This feature will be available soon.');
  }

  Widget _buildHeader(BuildContext context, bool isBooking) {
    final bool isOnboarding = mode == MembershipPlanMode.onboarding;
    return Padding(
      padding: AppSpacing.sm.bPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSpacing.xs.h,

          // 1. VIP Membership Top Badge
          Center(
            child: QuickContainer(
              px: AppSpacing.mlg,
              py: AppSpacing.ssm,
              radius: AppRadius.round,
              color: context.colors.surfaceDim,
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.5),
                width: 1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Assets.svg.badge.svg(height: AppSizes.iconXs),
                  AppSpacing.xs.w,
                  Text(
                    'VIP MEMBERSHIP',
                    style: context.textTheme.labelSmall
                        ?.colour(context.colors.primary)
                        .textSpacing(1.0),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.md.h,

          // 2. Headline
          Text(
            isOnboarding ? 'Select Membership Plan' : 'Unlock Instant Savings',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineMedium?.bold(),
          ),
          AppSpacing.xs.h,

          // 3. Subtitle Description
          if (isOnboarding)
            Text(
              'Select an elite membership tier to unlock priority dispatch, verified operative pools, and exclusive member discounts.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium
                  ?.colour(context.colors.onSurfaceVariant)
                  .lineHeight(1.35),
            )
          else if (isBooking)
            AppRichText(
              textAlign: TextAlign.center,
              spans: [
                AppTextSpan(
                  text: 'Apply instant tier discounts to your ',
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
                AppTextSpan(
                  text: (bookingAmount ?? 240.0).toInrAmount,
                  style: context.textTheme.bodyMedium?.semiBold(),
                ),
                AppTextSpan(
                  text: ' booking with ',
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
                AppTextSpan(
                  text: operativeName ?? 'Operative Vikram Singh',
                  style: context.textTheme.bodyMedium?.semiBold(),
                ),
                AppTextSpan(
                  text: '.',
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else
            Text(
              'Apply instant tier discounts and unlock priority rapid-escort dispatches and vetted operative pools.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium
                  ?.colour(context.colors.onSurfaceVariant)
                  .lineHeight(1.35),
            ),
          AppSpacing.lg.h,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isBooking = mode == MembershipPlanMode.booking;
    final bool isOnboarding = mode == MembershipPlanMode.onboarding;

    return BlocBuilder<MembershipPlansBloc, MembershipPlansState>(
      builder: (context, state) {
        final plans = state.plans;
        final isLoading = state.loadStatus.isLoading;
        final selectedPlan = state.selectedPlan;
        final activePlanId = state.activePlanId;
        final isCurrent =
            selectedPlan != null &&
            selectedPlan.id == activePlanId &&
            !isBooking &&
            !isOnboarding;

        return Scaffold(
          appBar: AppAppBar.transparent(
            showBackIcon: !isOnboarding,
            actions: const [],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: context.colors.primary,
              backgroundColor: context.colors.surface,
              onRefresh: () async {
                final bloc = context.read<MembershipPlansBloc>();
                bloc.add(
                  MembershipPlansStarted(activePlanId: state.activePlanId),
                );
                await bloc.stream.firstWhere((s) => !s.loadStatus.isLoading);
              },
              child: (isLoading && plans.isEmpty)
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primary,
                      ),
                    )
                  : (state.loadStatus.isFailure && plans.isEmpty)
                  ? Center(
                      child: Padding(
                        padding: context.horizontalEdgeInsets,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.apiErrorText(
                                state.loadStatus.errorOrNull,
                                fallback: state.loadStatus.errorMessageOrNull,
                              ),
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodyMedium,
                            ),
                            AppSpacing.md.h,
                            AppButton(
                              text: 'Retry',
                              onPressed: () => context
                                  .read<MembershipPlansBloc>()
                                  .add(
                                    MembershipPlansStarted(
                                      activePlanId: state.activePlanId,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding:
                          context.horizontalEdgeInsets + AppSpacing.md.bPadding,
                      itemCount: plans.length + 1, // Header + plans
                      separatorBuilder: (context, index) {
                        if (index == 0) return const SizedBox.shrink();
                        return AppSpacing.md.h;
                      },
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildHeader(context, isBooking);
                        }

                        final plan = plans[index - 1];
                        final isSelected = selectedPlan?.id == plan.id;
                        final isCurrentPlan =
                            !isBooking &&
                            !isOnboarding &&
                            plan.id == activePlanId;

                        return PlanSelectionCard(
                          plan: plan,
                          isSelected: isSelected,
                          isCurrentPlan: isCurrentPlan,
                          bookingAmount: isBooking
                              ? (bookingAmount ?? 240.0)
                              : null,
                          onTap: () => context
                              .read<MembershipPlansBloc>()
                              .add(MembershipPlanSelected(plan)),
                        );
                      },
                    ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
              child: (isBooking || isOnboarding)
                  ? Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: AppButton(
                            text: 'Apply ${selectedPlan?.title ?? 'Plan'}',
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFE2B755), Color(0xFFC48E28)],
                            ),
                            foregroundColor: const Color(0xFF191B23),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            height: 52,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC48E28)
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            trailing: const Icon(
                              Icons.arrow_forward_rounded,
                              size: AppSizes.iconSmd,
                              color: Color(0xFF191B23),
                            ),
                            onPressed: selectedPlan != null
                                ? _handleAction
                                : null,
                          ),
                        ),
                        AppSpacing.md.w,
                        Expanded(
                          flex: 4,
                          child: AppButton(
                            text: 'Skip',
                            backgroundColor: const Color(0xFF262A34),
                            foregroundColor: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            height: 52,
                            onPressed: () =>
                                context.go(CustomerHomeScreen.route),
                          ),
                        ),
                      ],
                    )
                  : AppButton(
                      text: isCurrent ? 'Current Plan' : 'Upgrade your plan',
                      gradient: isCurrent
                          ? null
                          : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFFE2B755), Color(0xFFC48E28)],
                            ),
                      foregroundColor:
                          isCurrent ? null : const Color(0xFF191B23),
                      backgroundColor: isCurrent
                          ? context.colors.surfaceContainerHigh
                          : null,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      height: 52,
                      boxShadow: isCurrent
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFFC48E28)
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle_outline_rounded,
                              size: AppSizes.iconSmd,
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              size: AppSizes.iconSmd,
                              color: Color(0xFF191B23),
                            ),
                      onPressed: (selectedPlan != null && !isCurrent)
                          ? _handleAction
                          : null,
                    ),
            ),
          ),
        );
      },
    );
  }
}
