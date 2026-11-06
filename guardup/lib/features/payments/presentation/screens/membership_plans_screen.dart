import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/pagination/app_pagination.dart';
import '/shared/widgets/pagination/pagination.controller.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/core/state/api_state.dart';
import '../../data/model/plan.model.dart';
import '../widgets/plan_selection_card.dart';

/// The invocation mode defining header text, badges, and bottom action buttons.
enum MembershipPlanMode {
  /// Invoked during booking / checkout to apply instant discounts.
  @JsonValue('BOOKING')
  booking('BOOKING'),

  /// Invoked from Profile -> Membership Plan to view or upgrade membership.
  @JsonValue('PROFILE')
  profile('PROFILE');

  final String apiValue;

  const MembershipPlanMode(this.apiValue);

  static MembershipPlanMode fromApiValue(String? value) {
    if (value == null) return MembershipPlanMode.profile;
    return MembershipPlanMode.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => MembershipPlanMode.profile,
    );
  }

  static MembershipPlanMode? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return MembershipPlanMode.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Named record typedef for navigation arguments to [MembershipPlansScreen].
typedef MembershipPlanArgs = ({
  MembershipPlanMode? mode,
  double? bookingAmount,
  String? operativeName,
  String? activePlanId,
});

class MembershipPlansScreen extends StatefulWidget {
  final MembershipPlanMode mode;
  final double? bookingAmount;
  final String? operativeName;
  final String? activePlanId;

  const MembershipPlansScreen({
    super.key,
    this.mode = MembershipPlanMode.booking,
    this.bookingAmount = 240.0,
    this.operativeName = 'Operative Vikram Singh',
    this.activePlanId = 'gold_sentinel',
  });

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  late final _selectedPlanNotifier = ValueNotifier<PlanModel>(
    PlanModel.fakeData.firstWhere(
      (p) => p.id == widget.activePlanId,
      orElse: () => PlanModel.fakeData.first,
    ),
  );

  final _paginationController = PaginationController<PlanModel>(
    initialState: PaginationState<PlanModel>(
      items: PlanModel.fakeData,
      total: PlanModel.fakeData.length,
      status: ApiState.success(null),
    ),
  );

  @override
  void dispose() {
    _selectedPlanNotifier.dispose();
    _paginationController.dispose();
    super.dispose();
  }

  void _handleAction() {
    widget.mode == MembershipPlanMode.booking
        ? context.go(AppRoutes.home)
        : context.pop();
  }

  Widget _buildHeader(BuildContext context, bool isBooking) {
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
            'Unlock Instant Savings',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineMedium?.bold(),
          ),
          AppSpacing.xs.h,

          // 3. Subtitle Description
          if (isBooking)
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
                  text: (widget.bookingAmount ?? 240.0).toUsd,
                  style: context.textTheme.bodyMedium?.semiBold(),
                ),
                AppTextSpan(
                  text: ' booking with ',
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
                AppTextSpan(
                  text: widget.operativeName ?? 'Operative Vikram Singh',
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
    final bool isBooking = widget.mode == MembershipPlanMode.booking;

    return Scaffold(
      appBar: const AppAppBar.transparent(showBackIcon: true, actions: []),
      body: SafeArea(
        child: ValueListenableBuilder<PlanModel>(
          valueListenable: _selectedPlanNotifier,
          builder: (context, selectedPlan, _) {
            return AppPagination<PlanModel>.list(
              controller: _paginationController,
              padding: context.horizontalEdgeInsets + AppSpacing.md.bPadding,
              header: _buildHeader(context, isBooking),
              separatorBuilder: (context, index) => AppSpacing.md.h,
              itemBuilder: (context, plan, index) {
                return PlanSelectionCard(
                  plan: plan,
                  isSelected: selectedPlan.id == plan.id,
                  isCurrentPlan: !isBooking && plan.id == widget.activePlanId,
                  bookingAmount: isBooking
                      ? (widget.bookingAmount ?? 240.0)
                      : null,
                  onTap: () => _selectedPlanNotifier.value = plan,
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
          child: ValueListenableBuilder<PlanModel>(
            valueListenable: _selectedPlanNotifier,
            builder: (context, selectedPlan, _) {
              if (isBooking) {
                return Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: AppButton(
                        text: 'Apply ${selectedPlan.title}',
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          size: AppSizes.iconSmd,
                        ),
                        onPressed: _handleAction,
                      ),
                    ),
                    AppSpacing.md.w,
                    Expanded(
                      flex: 4,
                      child: AppButton(
                        text: 'Skip',
                        type: ButtonType.secondaryOff,
                        onPressed: () => context.go(AppRoutes.home),
                      ),
                    ),
                  ],
                );
              }

              return AppButton(
                text: 'Upgrade your plan',

                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.iconSmd,
                ),
                onPressed: _handleAction,
              );
            },
          ),
        ),
      ),
    );
  }
}
