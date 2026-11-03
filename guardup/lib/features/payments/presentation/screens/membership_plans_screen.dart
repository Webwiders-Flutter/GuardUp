import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/app/routes/app_routes.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/selection/selection.controller.dart';
import '../../data/model/plan.model.dart';
import '../widgets/plan_selection_card.dart';

/// The invocation mode defining header text, badges, and bottom action buttons.
enum MembershipPlanMode {
  /// Invoked during booking / checkout to apply instant discounts.
  booking,

  /// Invoked from Profile -> Membership Plan to view or upgrade membership.
  profile,
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
  late final List<PlanModel> _plans;
  late final SelectionController<PlanModel> _selectionController;
  final ValueNotifier<bool> _isProcessingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _plans = PlanModel.fakePlans;

    // Default select the active plan or the most popular plan
    final initialPlan = _plans.firstWhere(
      (p) => p.id == (widget.activePlanId ?? 'gold_sentinel'),
      orElse: () => _plans[1],
    );

    _selectionController = SelectionController<PlanModel>.single(
      initial: initialPlan,
    );
  }

  @override
  void dispose() {
    _selectionController.dispose();
    _isProcessingNotifier.dispose();
    super.dispose();
  }

  void _handleAction() {
    final selected = _selectionController.selectedItem;
    if (selected == null) return;

    _isProcessingNotifier.value = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _isProcessingNotifier.value = false;

      final message = widget.mode == MembershipPlanMode.booking
          ? '${selected.title} applied to booking!'
          : 'Subscribed to ${selected.title} successfully!';

      AppSnackbar.success(message, context: context);
      widget.mode == .booking ? context.go(AppRoutes.home) : context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isBooking = widget.mode == MembershipPlanMode.booking;

    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(showBackIcon: true, actions: const []),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            color: context.colors.primary.withValues(
                              alpha: 0.5,
                            ),
                            width: 1,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Assets.svg.badge.svg(height: 14),
                              AppSpacing.xs.w,
                              Text(
                                'VIP MEMBERSHIP',
                                style: context.textTheme.labelSmall
                                    ?.bold()
                                    .colour(context.colors.primary)
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
                        style: context.textTheme.headlineMedium?.bold().colour(
                          context.colors.onSurface,
                        ),
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
                              text:
                                  '\$${(widget.bookingAmount ?? 240.0).toStringAsFixed(2)}',
                              style: context.textTheme.bodyMedium
                                  ?.semiBold()
                                  .colour(context.colors.onSurface),
                            ),
                            AppTextSpan(
                              text: ' booking with ',
                              style: context.textTheme.bodyMedium?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                            ),
                            AppTextSpan(
                              text:
                                  widget.operativeName ??
                                  'Operative Vikram Singh',
                              style: context.textTheme.bodyMedium
                                  ?.semiBold()
                                  .colour(context.colors.onSurface),
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
                      AppSpacing.xl.h,

                      // 4. Plans List
                      ValueListenableBuilder<List<PlanModel>>(
                        valueListenable: _selectionController,
                        builder: (context, _, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < _plans.length; i++) ...[
                                if (i > 0) AppSpacing.md.h,
                                PlanSelectionCard(
                                  controller: _selectionController,
                                  plan: _plans[i],
                                  isCurrentPlan:
                                      !isBooking &&
                                      _plans[i].id == widget.activePlanId,
                                  bookingAmount: isBooking
                                      ? (widget.bookingAmount ?? 240.0)
                                      : null,
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      const Spacer(),
                      AppSpacing.lg.h,

                      // 5. Bottom Action Buttons
                      ValueListenableBuilder<bool>(
                        valueListenable: _isProcessingNotifier,
                        builder: (context, isProcessing, _) {
                          return ValueListenableBuilder<List<PlanModel>>(
                            valueListenable: _selectionController,
                            builder: (context, selection, _) {
                              final selectedPlan = selection.isNotEmpty
                                  ? selection.first
                                  : null;

                              if (isBooking) {
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: AppButton(
                                        text: selectedPlan != null
                                            ? 'Apply ${selectedPlan.title}'
                                            : 'Apply Plan',
                                        trailing: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                        isLoading: isProcessing,
                                        onPressed: _handleAction,
                                      ),
                                    ),
                                    AppSpacing.md.w,
                                    Expanded(
                                      flex: 4,
                                      child: AppButton(
                                        text: 'Skip',
                                        type: ButtonType.secondaryOff,
                                        onPressed: () =>
                                            context.go(AppRoutes.home),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return AppButton(
                                text: 'Upgrade your plan',
                                size: ButtonSize.large,
                                trailing: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                isLoading: isProcessing,
                                onPressed: _handleAction,
                              );
                            },
                          );
                        },
                      ),
                      AppSpacing.xl.h,
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
}
