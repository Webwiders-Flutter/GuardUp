import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';

// import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/layout.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/buttons/app_button.dart';
// import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_detail_section.dart';
import '/shared/widgets/sections/app_metric_card.dart';
import '/shared/widgets/state/app_state_view.dart';
import '../../data/models/membership_plan.model.dart';
import '../../di/membership_plan.providers.dart';
import 'membership_plan.form.dart';

/// Full view of a single membership plan: pricing, discount, benefits and
/// record metadata, with edit / activate / delete actions.
class MembershipPlanDetailsScreen extends ConsumerWidget {
  const MembershipPlanDetailsScreen({
    super.key,
    required this.planId,
    this.asSidebar = false,
  });

  final String planId;
  final bool asSidebar;

  /// Opens the details in the right-side slide-in panel.
  static Future<void> showAsSidebar({
    required BuildContext context,
    required String planId,
  }) {
    return AppSidePanel.show<void>(
      context: context,
      title: 'Membership Plan Details',
      subtitle: 'Pricing, booking discount, benefits and status',
      width: 65.wPercent(context),
      showFooter: false,
      body: MembershipPlanDetailsScreen(planId: planId, asSidebar: true),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlan = ref.watch(membershipPlanDetailsProvider(planId));

    final body = asyncPlan.when(
      skipLoadingOnReload: true,
      loading: () => const AppStateView(type: AppViewType.loading),
      error: (error, _) => AppStateView(
        type: AppViewType.error,
        message: 'Failed to load membership plan',
        subtitle: asyncPlan.errorMessage,
        actionText: 'Retry',
        onAction: () => ref.invalidate(membershipPlanDetailsProvider(planId)),
      ),
      data: (plan) => _PlanDetailsBody(plan: plan),
    );

    if (asSidebar) {
      return SizedBox(height: context.screenHeight, child: body);
    }

    return Scaffold(
      backgroundColor: context.colors.backgroundLight,
      appBar: AppAppBar.transparent(title: 'Membership Plan Details'),
      body: body,
    );
  }
}

class _PlanDetailsBody extends StatelessWidget {
  const _PlanDetailsBody({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _PlanHero(plan: plan),
        AppSpacing.md.h,
        _PlanQuickStats(plan: plan),
        AppSpacing.lg.h,
        LayoutBuilder(
          builder: (context, constraints) {
            final benefits = _BenefitsSection(plan: plan);
            final pricing = _PricingSection(plan: plan);

            if (constraints.maxWidth < 900) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [benefits, AppSpacing.md.h, pricing],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: benefits),
                AppSpacing.md.w,
                Expanded(child: pricing),
              ],
            );
          },
        ),
        AppSpacing.xxxl.h,
      ],
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _PlanHero extends ConsumerWidget {
  const _PlanHero({required this.plan});

  final MembershipPlan plan;

  Future<void> _onEdit(BuildContext context) async {
    await MembershipPlanFormScreen.showAsSidebar(context: context, plan: plan);
  }

  Future<void> _onToggleActive(WidgetRef ref) async {
    final controller = ref.read(membershipPlanControllerProvider.notifier);
    await controller.toggleActiveStatus(plan.id, !plan.isActive);

    final saved = ref
        .read(membershipPlanControllerProvider)
        .handleResult(
          successMessage: plan.isActive
              ? '${plan.name} deactivated'
              : '${plan.name} activated',
          fallbackErrorMessage: 'Failed to update plan status',
        );
    if (saved) ref.invalidate(membershipPlanDetailsProvider(plan.id));
  }

  // Delete is disabled for now.
  // Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    // final result = await AppPopup.showDeleteConfirmation(
      // context,
      // deleteItemName: plan.name,
    // );
    // if (result?.action != PopupAction.confirm || !context.mounted) return;

    // await ref
        // .read(membershipPlanControllerProvider.notifier)
        // .deleteRecord(plan.id);
    // if (!context.mounted) return;

    // final deleted = ref
        // .read(membershipPlanControllerProvider)
        // .handleResult(
          // successMessage: '${plan.name} deleted successfully',
          // fallbackErrorMessage: 'Failed to delete membership plan',
        // );
    // if (!deleted) return;

    // if (context.canPop()) {
      // context.pop();
    // } else {
      // context.go(AppRoutes.membershipPlans);
    // }
  // }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accent = plan.isPopular ? colors.warning : colors.primary;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.borderLight.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdRadius,
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  size: AppSpacing.xxl,
                  color: accent,
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          plan.name,
                          style: context.textTheme.titleMedium?.bold(),
                        ),
                        AppChip(
                          color: plan.isActive ? colors.success : colors.error,
                          title: plan.isActive ? 'Active' : 'Inactive',
                          icon: plan.isActive
                              ? Icons.check_circle_outline_rounded
                              : Icons.pause_circle_outline_rounded,
                          size: AppChipSize.small,
                        ),
                        if (plan.isPopular)
                          AppChip(
                            color: colors.warning,
                            title: 'Most Popular',
                            icon: Icons.star_rounded,
                            size: AppChipSize.small,
                          ),
                        _IdChip(id: plan.id),
                      ],
                    ),
                    AppSpacing.sm.h,
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: plan.pricePerMonth.toUsdAmount,
                            style: context.textTheme.titleLarge
                                ?.bold()
                                .colour(colors.primary),
                          ),
                          TextSpan(
                            text: ' / month',
                            style: context.textTheme.bodyMedium?.colour(
                              colors.onSurfaceSecondary,
                            ),
                          ),
                          if (plan.hasYearlyPrice)
                            TextSpan(
                              text:
                                  '   ·   ${plan.pricePerYear!.toUsdAmount} / year',
                              style: context.textTheme.bodyMedium
                                  ?.semiBold()
                                  .colour(colors.onSurfaceSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.md.h,
          Divider(color: colors.borderLight.withValues(alpha: 0.6), height: 1),
          AppSpacing.md.h,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                text: 'Edit Plan',
                leading: Icon(
                  Icons.edit_outlined,
                  size: AppSpacing.md + 2,
                  color: colors.onPrimary,
                ),
                size: ButtonSize.small,
                fullWidth: false,
                onPressed: () => _onEdit(context),
              ),
              AppButton(
                text: plan.isActive ? 'Deactivate' : 'Activate',
                leading: Icon(
                  plan.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  size: AppSpacing.md + 2,
                ),
                size: ButtonSize.small,
                type: plan.isActive ? ButtonType.warning : ButtonType.success,
                fullWidth: false,
                onPressed: () => _onToggleActive(ref),
              ),
              // Delete is disabled for now.
              // AppButton(
                // text: 'Delete',
                // leading: Icon(
                  // Icons.delete_outline_rounded,
                  // size: AppSpacing.md + 2,
                // ),
                // size: ButtonSize.small,
                // type: ButtonType.danger,
                // fullWidth: false,
                // onPressed: () => _onDelete(context, ref),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdChip extends StatelessWidget {
  const _IdChip({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: id));
        AppSnackbar.show(
          message: 'Plan ID copied to clipboard',
          type: SnackbarType.success,
        );
      },
      borderRadius: AppRadius.fullRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundLight,
          borderRadius: AppRadius.fullRadius,
          border: Border.all(color: colors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ID: #${id.length > 8 ? id.substring(0, 8) : id}',
              style: context.textTheme.bodySmall
                  ?.semiBold()
                  .colour(colors.onSurfaceSecondary),
            ),
            AppSpacing.xs.w,
            Icon(
              Icons.copy_rounded,
              size: AppSpacing.sm + 2,
              color: colors.onSurfaceSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick stats ──────────────────────────────────────────────────────────────

class _PlanQuickStats extends StatelessWidget {
  const _PlanQuickStats({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final savingsPercent = plan.yearlySavingsPercent;

    final cards = <Widget>[
      AppMetricCard(
        label: 'Monthly Price',
        value: plan.pricePerMonth.toUsdAmount,
        icon: Icons.calendar_view_month_outlined,
        color: colors.primary,
      ),
      AppMetricCard(
        label: 'Yearly Price',
        value: plan.pricePerYear.toUsdAmountOr('Not offered'),
        subtitle: savingsPercent != null
            ? 'Saves $savingsPercent% vs. monthly'
            : null,
        icon: Icons.event_repeat_outlined,
        color: colors.secondary,
      ),
      AppMetricCard(
        label: 'Booking Discount',
        value: plan.discountLabel,
        icon: plan.discountType.icon,
        color: colors.success,
      ),
      AppMetricCard(
        label: 'Benefits',
        value: '${plan.description.length} listed',
        icon: Icons.checklist_rounded,
        color: colors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth < 700 ? 2 : cards.length;
        final cardWidth =
            (constraints.maxWidth - AppSpacing.sm * (perRow - 1)) / perRow;

        return Row(
          spacing: AppSpacing.sm,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

// ─── Sections ─────────────────────────────────────────────────────────────────

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final benefits = plan.description;

    return AppDetailSection(
      title: 'Plan Benefits',
      subtitle: 'Shown to customers on the plan card',
      icon: Icons.checklist_rounded,
      iconColor: colors.success,
      child: benefits.isEmpty
          ? Text(
              'No benefits have been added to this plan yet.',
              style: context.textTheme.bodyMedium?.colour(
                colors.onSurfaceSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final benefit in benefits)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: AppSpacing.md + 2,
                          color: colors.success,
                        ),
                        AppSpacing.sm.w,
                        Expanded(
                          child: Text(
                            benefit,
                            style: context.textTheme.bodyMedium?.medium(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context) {
    final savings = plan.yearlySavings;

    return AppDetailSection(
      title: 'Pricing & Discount',
      subtitle: 'Configuration stored for this plan',
      icon: Icons.sell_outlined,
      items: [
        (
          label: 'Price per month',
          value: plan.pricePerMonth.toUsdAmount,
          icon: Icons.calendar_view_month_outlined,
        ),
        (
          label: 'Price per year',
          value: plan.pricePerYear.toUsdAmountOr('Not offered'),
          icon: Icons.event_repeat_outlined,
        ),
        if (savings != null)
          (
            label: 'Yearly saving',
            value:
                '${savings.toUsdAmount} (${plan.yearlySavingsPercent}%) vs. ${plan.yearlyPriceAtMonthlyRate.toUsdAmount} paid monthly',
            icon: Icons.savings_outlined,
          ),
        (
          label: 'Discount type',
          value: plan.discountType.label,
          icon: plan.discountType.icon,
        ),
        (
          label: 'Discount',
          value: plan.discountLabel,
          icon: Icons.local_offer_outlined,
        ),
        if (plan.discountType.isPercentage)
          (
            label: 'Maximum discount per booking',
            value: plan.discountUpto.toUsdAmountOr('No limit'),
            icon: Icons.vertical_align_top_rounded,
          ),
        (
          label: 'Created on',
          value: plan.createdAt?.fullDateTime ?? '—',
          icon: Icons.event_available_outlined,
        ),
        (
          label: 'Last updated',
          value: plan.updatedAt?.fullDateTime ?? '—',
          icon: Icons.update_rounded,
        ),
      ],
    );
  }
}
