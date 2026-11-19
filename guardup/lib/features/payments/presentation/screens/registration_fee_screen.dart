import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_sizes.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/config/admin_settings/admin_settings.dart';
import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/transaction_type.enum.dart';
import '../../data/model/transaction.model.dart';

/// Screen presenting the one-time registration fee for verification and priority onboarding.
class RegistrationFeeScreen extends StatefulWidget {
  static const route = '/registration-fee';

  const RegistrationFeeScreen({super.key});

  @override
  State<RegistrationFeeScreen> createState() => _RegistrationFeeScreenState();
}

class _RegistrationFeeScreenState extends State<RegistrationFeeScreen> {
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  UserModel get _currentUser {
    final authState = sl<AuthBloc>().state;
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;

    return UserModel(
      id:
          currentUserId ??
          authState.user?.id ??
          'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: authState.displayName.isNotEmpty
          ? authState.displayName
          : (authState.user?.name ?? 'User'),
      role: authState.user?.role ?? authState.sessionRole,
      profileImageUrl:
          (authState.userData?['profile_image_url'] as String?) ??
          authState.user?.profileImageUrl,
    );
  }

  double get _registrationFee {
    return context.read<AdminSettingsCubit>().getRegistrationFee(_currentUser.role);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_isLoadingNotifier.value) return;
    _isLoadingNotifier.value = true;

    try {
      final currentUserId = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUserId
          : null;

      // 1. Generate unique dummy payment reference ID and transaction ID
      final feeAmount = _registrationFee;
      final randomNum = math.Random().nextInt(900000) + 100000;
      final dummyReferenceId = '#GD-$randomNum';
      final dummyPaymentId =
          'pay_stripe_${DateTime.now().millisecondsSinceEpoch}';

      // 2. Persist dummy payment details in database (public.users)
      if (currentUserId != null && sl.isRegistered<UserRepository>()) {
        try {
          await sl<UserRepository>().updateProfileFields(
            userId: currentUserId,
            data: {
              'status': 'PENDING_APPROVAL',
              'metadata': {
                'payment_status': 'PAID',
                'payment_id': dummyPaymentId,
                'payment_reference': dummyReferenceId,
                'payment_amount': feeAmount,
                'payment_currency': 'USD',
                'payment_date': DateTime.now().toIso8601String(),
              },
            },
          );
        } catch (_) {}
      }

      // 3. Update AuthBloc user status to pendingApproval
      sl<AuthBloc>().add(
        const AuthUpdateUserStatusRequested(UserStatus.pendingApproval),
      );

      final effectiveUser = _currentUser;

      if (mounted) {
        _isLoadingNotifier.value = false;

        // 4. Navigate to luxury PaymentSuccessScreen
        context.go(
          AppRoutes.paymentSuccess,
          extra: {
            'transaction': TransactionModel(
              id: dummyPaymentId,
              referenceId: dummyReferenceId,
              bookingId: dummyReferenceId,
              amount: feeAmount,
              currency: 'USD',
              type: TransactionType.debit,
              title: 'Registration Fee',
              gateway: 'Stripe Verified',
              scheduleText: 'Today, 2:00 PM – 4:00 PM',
              dateTime: DateTime.now(),
              discountNote: context.l10n.incMembershipDiscount,
            ),
            'user': effectiveUser,
            'buttonText': context.l10n.next,
            'onTap': () => context.go(AppRoutes.adminApproval),
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _isLoadingNotifier.value = false;
        AppSnackbar.error('Payment processing failed. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        alignTitle: .center,
        titleWidget: Assets.svg.appBanner.svg(height: AppSizes.iconLg),
        actions: [
          IconButton(
            tooltip: context.l10n.logOut,
            icon: Icon(
              Icons.logout_rounded,
              color: context.colors.error,
              size: AppSizes.iconSmd,
            ),
            onPressed: () async {
              final result = await AppPopup.showLogoutConfirmation(context);
              if (result?.action == PopupAction.confirm && context.mounted) {
                sl<AuthBloc>().add(const AuthSignOutRequested());
                context.go(AppRoutes.login);
              }
            },
          ),
          AppSpacing.xs.w,
        ],
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

                      // Registration Fee Card via WrapperCard
                      WrapperCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.xxl,
                        ),
                        borderColor: context.colors.primaryContainer,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Dollar Coin Badge
                            QuickContainer(
                              w: AppSizes.iconGiant,
                              h: AppSizes.iconGiant,
                              radius: AppRadius.full,
                              color: context.colors.primary.withValues(
                                alpha: 0.15,
                              ),
                              border: Border.all(
                                color: context.colors.primary.withValues(
                                  alpha: 0.45,
                                ),
                                width: 1.5,
                              ),
                              alignment: Alignment.center,
                              child: Assets.svg.dollar.svg(
                                width: AppSizes.iconLg,
                                height: AppSizes.iconLg,
                              ),
                            ),
                            AppSpacing.lg.h,

                            // 2. Title
                            Text(
                              context.l10n.oneTimeRegistrationFee,
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleMedium
                                  ?.bold()
                                  .textSpacing(0.8),
                            ),
                            AppSpacing.xs.h,

                            // 3. Subtitle / Description
                            Text(
                              context.l10n.registrationFeeSubtitle,
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall
                                  ?.colour(context.colors.onSurfaceVariant)
                                  .lineHeight(1.35),
                            ),
                            AppSpacing.xxl.h,

                            // 4. Price & Lifetime Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _registrationFee.toUsd,
                                  style: context.textTheme.headlineLarge
                                      ?.bold()
                                      .colour(context.colors.primary)
                                      .increaseSize(4)
                                      .lineHeight(1.0),
                                ),
                                AppSpacing.xs.w,
                                Text(
                                  '/ ${context.l10n.lifetime}',
                                  style: context.textTheme.labelMedium
                                      ?.colour(context.colors.onSurfaceVariant)
                                      .textSpacing(0.8),
                                ),
                              ],
                            ),
                            AppSpacing.xxl.h,

                            // 5. Secure Stripe Pill Badge
                            QuickContainer(
                              px: AppSpacing.lg,
                              py: AppSpacing.sm,
                              radius: AppRadius.round,
                              color: Colors.black,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: AppSizes.iconSm,
                                    color: context.colors.success,
                                  ),
                                  AppSpacing.xs.w,
                                  Text(
                                    context.l10n.securePaymentWithStripe,
                                    style: context.textTheme.labelSmall?.colour(
                                      context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.xl.h,

                            // 6. Pay Now Button (with primary glow and loading)
                            ValueListenableBuilder<bool>(
                              valueListenable: _isLoadingNotifier,
                              builder: (context, isLoading, _) {
                                return AppButton(
                                  text: context.l10n.payNow,
                                  isLoading: isLoading,
                                  makeItGlow: true,
                                  onPressed: _handlePayment,
                                );
                              },
                            ),
                            AppSpacing.lg.h,

                            // 7. Powered by Stripe Footer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '${context.l10n.poweredBy}  ',
                                  style: context.textTheme.labelSmall?.colour(
                                    context.colors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'stripe',
                                  style: context.textTheme.titleSmall
                                      ?.textSpacing(-0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
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
