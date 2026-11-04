import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/payments/payments.dart';

import '../../data/enum/user_role.enum.dart';
import '/app/routes/app_routes.dart';
import '/core/constants/app_constants.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/sections/app_image.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _countdownTimer;
  final ValueNotifier<int> _secondsRemainingNotifier = ValueNotifier<int>(
    AppConstants.resendSeconds,
  );

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemainingNotifier.value = AppConstants.resendSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemainingNotifier.value > 1) {
        _secondsRemainingNotifier.value--;
      } else {
        _secondsRemainingNotifier.value = 0;
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _secondsRemainingNotifier.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final role = sl<AuthBloc>().state.sessionRole ?? UserRole.customer;
    switch (role) {
      case UserRole.customer:
        context.go(
          AppRoutes.membershipPlans,
          extra: (
            mode: MembershipPlanMode.booking,
            bookingAmount: null,
            operativeName: null,
            activePlanId: null,
          ),
        );
      case UserRole.guard:
        context.go(AppRoutes.bodyguardProfile);
      case UserRole.company:
        context.go(AppRoutes.companyProfile);
    }
  }

  void _handleResendEmail() {
    if (_secondsRemainingNotifier.value > 0) return;
    _startCountdown();
    AppSnackbar.success(
      context.l10n.emailVerificationSubtitle,
      context: context,
    );
  }

  void _handleLogout() {
    sl<AuthBloc>().add(const AuthSignOutRequested());
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
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
                      AppSpacing.huge.h,

                      // GuardUp Logo (Centered)
                      Center(
                        child: AppImage.asset(
                          assetPath: Assets.images.appLogo.path,
                          height: 32.wPercent(context),
                          fit: BoxFit.contain,
                        ),
                      ),
                      AppSpacing.colossal.h,

                      // 1. Heading
                      Text(
                        context.l10n.emailVerificationTitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineLarge?.bold(),
                      ),
                      AppSpacing.sm.h,

                      // 2. Subtitle
                      Text(
                        context.l10n.emailVerificationSubtitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.xxl.h,

                      // 3. Continue Primary Button
                      AppButton(
                        text: context.l10n.continueButton,
                        size: ButtonSize.large,
                        onPressed: _handleContinue,
                      ),
                      AppSpacing.md.h,

                      // 4. Resend Email (Text Button with Countdown Timer via ValueListenableBuilder)
                      ValueListenableBuilder<int>(
                        valueListenable: _secondsRemainingNotifier,
                        builder: (context, secondsRemaining, _) {
                          return AppButton(
                            type: ButtonType.text,
                            size: ButtonSize.normal,
                            text: secondsRemaining > 0
                                ? context.l10n.resendEmailIn(secondsRemaining)
                                : context.l10n.resendEmail,
                            enabled: secondsRemaining == 0,
                            onPressed: secondsRemaining == 0
                                ? _handleResendEmail
                                : null,
                          );
                        },
                      ),

                      const Spacer(),

                      // 5. Bottom Logout Button
                      Center(
                        child: AppButton(
                          type: ButtonType.text,
                          size: ButtonSize.normal,
                          text: context.l10n.logOut,
                          onPressed: _handleLogout,
                        ),
                      ),
                      AppSpacing.md.h,
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
