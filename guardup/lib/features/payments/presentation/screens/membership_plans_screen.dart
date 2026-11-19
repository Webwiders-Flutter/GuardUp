import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:quick_container/quick_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/model/plan.model.dart';
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
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  final _plansNotifier = ValueNotifier<List<PlanModel>>(PlanModel.fakeData);
  final _isLoadingNotifier = ValueNotifier<bool>(true);
  final _isSubmittingNotifier = ValueNotifier<bool>(false);
  final _selectedPlanNotifier = ValueNotifier<PlanModel?>(null);
  late final _activePlanIdNotifier = ValueNotifier<String?>(
    widget.activePlanId,
  );

  @override
  void initState() {
    super.initState();
    _resolveActivePlanId();
    _loadPlans();
  }

  @override
  void dispose() {
    _plansNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isSubmittingNotifier.dispose();
    _selectedPlanNotifier.dispose();
    _activePlanIdNotifier.dispose();
    super.dispose();
  }

  void _resolveActivePlanId() {
    if (widget.activePlanId != null && widget.activePlanId!.isNotEmpty) {
      _activePlanIdNotifier.value = widget.activePlanId;
      return;
    }
    final authState = sl.isRegistered<AuthBloc>() ? sl<AuthBloc>().state : null;
    if (authState?.membershipPlanId != null &&
        authState!.membershipPlanId!.isNotEmpty) {
      _activePlanIdNotifier.value = authState.membershipPlanId;
    }
  }

  Future<void> _loadPlans() async {
    _isLoadingNotifier.value = true;
    try {
      final rows = await Supabase.instance.client
          .from(DatabaseTables.membershipPlans)
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final fetchedPlans = (rows as List)
          .map((r) => PlanModel.fromJson(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        if (fetchedPlans.isNotEmpty) {
          _plansNotifier.value = fetchedPlans;
        }
        _updateSelectedPlan();
      }
    } catch (e, stack) {
      debugPrint('Error loading dynamic membership plans: $e\n$stack');
      if (mounted && _plansNotifier.value.isEmpty) {
        _plansNotifier.value = PlanModel.fakeData;
        _updateSelectedPlan();
      }
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  void _updateSelectedPlan() {
    final plans = _plansNotifier.value;
    if (plans.isEmpty) return;

    final activeId = _activePlanIdNotifier.value;
    if (activeId != null && activeId.isNotEmpty) {
      final active = plans.where((p) => p.id == activeId).firstOrNull;
      if (active != null) {
        _selectedPlanNotifier.value = active;
        return;
      }
    }

    final popular = plans.where((p) => p.isPopular).firstOrNull;
    _selectedPlanNotifier.value = popular ?? plans.first;
  }

  Future<void> _handleAction() async {
    AppSnackbar.info('Coming Soon! This feature will be available soon.');

    // final selectedPlan = _selectedPlanNotifier.value;
    // if (selectedPlan == null) return;

    // final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // if (widget.mode == MembershipPlanMode.onboarding) {
    //   // 1. Signup / Onboarding flow: save membership plan to user & redirect home
    //   _isSubmittingNotifier.value = true;
    //   try {
    //     if (currentUserId != null) {
    //       await Supabase.instance.client
    //           .from(DatabaseTables.users)
    //           .update({'membership_plan_id': selectedPlan.id})
    //           .eq('id', currentUserId);

    //       if (sl.isRegistered<AuthBloc>()) {
    //         sl<AuthBloc>().add(const AuthReloadRoleDataRequested());
    //       }
    //     }
    //     if (mounted) {
    //       AppSnackbar.success('Welcome to ${selectedPlan.name}!');
    //       context.go(AppRoutes.home);
    //     }
    //   } catch (e) {
    //     debugPrint('Failed to save membership plan on onboarding: $e');
    //     if (mounted) {
    //       context.go(AppRoutes.home);
    //     }
    //   } finally {
    //     if (mounted) {
    //       _isSubmittingNotifier.value = false;
    //     }
    //   }
    //   return;
    // }

    // if (widget.mode == MembershipPlanMode.booking) {
    //   // 2. Booking flow: return chosen plan to checkout
    //   context.pop(selectedPlan);
    //   return;
    // }

    // // 3. Profile flow: Upgrade or switch plan
    // final activeId = _activePlanIdNotifier.value;
    // if (activeId == selectedPlan.id) {
    //   AppSnackbar.info(
    //     'You are already subscribed to the ${selectedPlan.name} plan.',
    //   );
    //   return;
    // }

    // _isSubmittingNotifier.value = true;
    // try {
    //   if (currentUserId != null) {
    //     await Supabase.instance.client
    //         .from(DatabaseTables.users)
    //         .update({'membership_plan_id': selectedPlan.id})
    //         .eq('id', currentUserId);

    //     _activePlanIdNotifier.value = selectedPlan.id;

    //     if (sl.isRegistered<AuthBloc>()) {
    //       sl<AuthBloc>().add(const AuthReloadRoleDataRequested());
    //     }
    //   }
    //   if (mounted) {
    //     AppSnackbar.success(
    //       'Membership plan updated to ${selectedPlan.name} successfully!',
    //     );
    //     context.pop();
    //   }
    // } catch (e) {
    //   debugPrint('Failed to update membership plan: $e');
    //   if (mounted) {
    //     AppSnackbar.error('Failed to update membership plan: $e');
    //   }
    // } finally {
    //   if (mounted) {
    //     _isSubmittingNotifier.value = false;
    //   }
    // }
  }

  Widget _buildHeader(BuildContext context, bool isBooking) {
    final bool isOnboarding = widget.mode == MembershipPlanMode.onboarding;
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
                  text: (widget.bookingAmount ?? 240.0).toInrAmount,
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
    final bool isOnboarding = widget.mode == MembershipPlanMode.onboarding;

    return Scaffold(
      appBar: AppAppBar.transparent(
        showBackIcon: !isOnboarding,
        actions: const [],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primary,
          backgroundColor: context.colors.surface,
          onRefresh: _loadPlans,
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _plansNotifier,
              _isLoadingNotifier,
              _selectedPlanNotifier,
              _activePlanIdNotifier,
            ]),
            builder: (context, _) {
              final plans = _plansNotifier.value;
              final isLoading = _isLoadingNotifier.value;
              final selectedPlan = _selectedPlanNotifier.value;
              final activePlanId = _activePlanIdNotifier.value;

              if (isLoading && plans.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: context.horizontalEdgeInsets + AppSpacing.md.bPadding,
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
                      !isBooking && !isOnboarding && plan.id == activePlanId;

                  return PlanSelectionCard(
                    plan: plan,
                    isSelected: isSelected,
                    isCurrentPlan: isCurrentPlan,
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _selectedPlanNotifier,
              _isSubmittingNotifier,
              _activePlanIdNotifier,
            ]),
            builder: (context, _) {
              final selectedPlan = _selectedPlanNotifier.value;
              final isSubmitting = _isSubmittingNotifier.value;
              final activePlanId = _activePlanIdNotifier.value;
              final isCurrent =
                  selectedPlan != null &&
                  selectedPlan.id == activePlanId &&
                  !isBooking &&
                  !isOnboarding;

              if (isBooking || isOnboarding) {
                return Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: AppButton(
                        text: 'Apply ${selectedPlan?.title ?? 'Plan'}',
                        isLoading: isSubmitting,
                        trailing: const Icon(
                          Icons.arrow_forward_rounded,
                          size: AppSizes.iconSmd,
                        ),
                        onPressed: selectedPlan != null ? _handleAction : null,
                      ),
                    ),
                    AppSpacing.md.w,
                    Expanded(
                      flex: 4,
                      child: AppButton(
                        text: 'Skip',
                        type: ButtonType.secondaryOff,
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.home),
                      ),
                    ),
                  ],
                );
              }

              return AppButton(
                text: isCurrent ? 'Current Plan' : 'Upgrade your plan',
                isLoading: isSubmitting,
                trailing: isCurrent
                    ? const Icon(
                        Icons.check_circle_outline_rounded,
                        size: AppSizes.iconSmd,
                      )
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        size: AppSizes.iconSmd,
                      ),
                onPressed: (selectedPlan != null && !isCurrent)
                    ? _handleAction
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
