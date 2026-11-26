import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/auth.dart';
import '/features/payments/presentation/screens/payment_success_screen.dart';
import '/features/settings/settings.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../bloc/registration_fee/registration_fee_bloc.dart';

/// Screen presenting the one-time registration fee for verification and priority onboarding.
class RegistrationFeeScreen extends StatelessWidget {
  static const route = '/registration-fee';

  const RegistrationFeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final role = authState.user?.role ?? authState.sessionRole;

    return BlocProvider(
      create: (_) => sl<RegistrationFeeBloc>(param1: role),
      child: _RegistrationFeeView(role: role),
    );
  }
}

class _RegistrationFeeView extends StatelessWidget {
  const _RegistrationFeeView({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final registrationFee = context.select<AdminSettingsCubit, double>(
      (cubit) => cubit.getRegistrationFee(role),
    );

    return BlocConsumer<RegistrationFeeBloc, RegistrationFeeState>(
      listenWhen: (prev, curr) => prev.paymentStatus != curr.paymentStatus,
      listener: (context, state) {
        if (state.paymentStatus.isSuccess) {
          final transaction = state.paymentStatus.dataOrNull;
          final user = context.read<AuthBloc>().state.user;
          context.go(
            PaymentSuccessScreen.route,
            extra: {
              'transaction': transaction,
              'user': user,
              'buttonText': context.l10n.next,
              'onTap': () => context.go(AdminApprovalScreen.route),
            },
          );
        } else if (state.paymentStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.paymentStatus.errorOrNull,
              fallback: 'Payment processing failed. Please try again.',
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.paymentStatus.isLoading;

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
                  if (result?.action == PopupAction.confirm &&
                      context.mounted) {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                    context.go(LoginScreen.route);
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
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      registrationFee.toUsd,
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
                                          ?.colour(
                                            context.colors.onSurfaceVariant,
                                          )
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
                                        style: context.textTheme.labelSmall
                                            ?.colour(
                                              context.colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                AppSpacing.xl.h,

                                // 6. Pay Now Button (with primary glow and loading)
                                AppButton(
                                  text: context.l10n.payNow,
                                  isLoading: isLoading,
                                  makeItGlow: true,
                                  onPressed: () {
                                    context.read<RegistrationFeeBloc>().add(
                                      RegistrationFeeSubmitted(
                                        discountNote:
                                            context.l10n.incMembershipDiscount,
                                      ),
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
                                      style: context.textTheme.labelSmall
                                          ?.colour(
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
      },
    );
  }
}
