import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:pinput/pinput.dart';

import '../../data/enum/otp_type.enum.dart';
import '../../data/enum/user_role.enum.dart';
import '/core/constants/app_constants.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/bloc/auth_state.dart';
import '/features/payments/presentation/screens/membership_plans_screen.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/features/body_guard/presentation/screens/body_guard_complete_profile_screen.dart';
import '/features/company/presentation/screens/company_complete_profile_screen.dart';
import '/features/auth/presentation/screens/login.screen.dart';
import '/features/auth/presentation/screens/reset_password.screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  static const route = '/emailVerification';

  final String? email;
  final UserRole? role;
  final OtpType otpType;

  const EmailVerificationScreen({
    super.key,
    this.email,
    this.role,
    this.otpType = OtpType.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const int _otpLength = 6;

  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _countdownTimer;
  final _secondsRemainingNotifier = ValueNotifier<int>(
    AppConstants.resendSeconds,
  );
  final _isLoadingNotifier = ValueNotifier<bool>(false);
  bool _isVerifying = false;

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
    _pinController.dispose();
    _focusNode.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  String get _targetEmail {
    if (widget.email != null && widget.email!.isNotEmpty) {
      return widget.email!;
    }
    final blocEmail = sl<AuthBloc>().state.email;
    if (blocEmail != null && blocEmail.isNotEmpty) {
      return blocEmail;
    }
    return '';
  }

  UserRole get _effectiveRole {
    return widget.role ?? sl<AuthBloc>().state.sessionRole;
  }

  void _handleVerifyOtp(String pin) {
    // Ignore duplicate submits (onCompleted + Continue button)
    if (_isLoadingNotifier.value) return;

    if (_targetEmail.isEmpty) {
      AppSnackbar.error('Missing target email. Please try signing in again.');
      return;
    }

    if (pin.length < _otpLength) {
      AppSnackbar.error('Please enter the full verification code');
      return;
    }

    _isVerifying = true;
    _isLoadingNotifier.value = true;

    sl<AuthBloc>().add(
      AuthVerifyOtpRequested(
        email: _targetEmail,
        token: pin,
        type: widget.otpType,
      ),
    );
  }

  void _navigateByRole() {
    switch (_effectiveRole) {
      case UserRole.customer:
        context.go(
          '${MembershipPlansScreen.route}?mode=onboarding',
          extra: (
            mode: MembershipPlanMode.onboarding,
            bookingAmount: null,
            operativeName: null,
            activePlanId: null,
          ),
        );
      case UserRole.guard:
        context.go(BodyGuardCompleteProfileScreen.route);
      case UserRole.company:
        context.go(CompanyCompleteProfileScreen.route);
    }
  }

  void _handleResendEmail() {
    if (_secondsRemainingNotifier.value > 0) return;
    if (_targetEmail.isEmpty) {
      AppSnackbar.error('No email address provided to resend code');
      return;
    }
    _startCountdown();
    sl<AuthBloc>().add(
      AuthResendOtpRequested(target: _targetEmail, type: widget.otpType),
    );
    AppSnackbar.info('A new verification code has been sent to $_targetEmail');
  }

  void _handleLogout() {
    sl<AuthBloc>().add(const AuthSignOutRequested());
    context.go(LoginScreen.route);
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isLoading) {
      _isLoadingNotifier.value = true;
      return;
    }

    _isLoadingNotifier.value = false;

    // Only process feedback when an active verification attempt was made
    if (!_isVerifying) return;

    if (state.isAuthenticated) {
      _isVerifying = false;
      if (widget.otpType == OtpType.recovery) {
        AppSnackbar.success('Verification code verified successfully');
        context.go(
          '${ResetPasswordScreen.route}?email=${Uri.encodeComponent(_targetEmail)}',
          extra: _targetEmail,
        );
        return;
      }
      AppSnackbar.success('Email verified successfully');
      _navigateByRole();
    } else if (state.hasError) {
      _isVerifying = false;
      _pinController.clear();
      _focusNode.requestFocus();
      AppSnackbar.error(
        state.errorMessage ??
            'Invalid verification code. Please check and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: context.textTheme.headlineSmall?.bold().colour(
        context.colors.onSurface,
      ),
      decoration: BoxDecoration(
        color: context.colors.onPrimary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: context.colors.primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: context.colors.surfaceDim,
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
    );

    return BlocListener<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      listener: _onAuthStateChanged,
      child: Scaffold(
        appBar: AppAppBar.transparent(
          showBackIcon: true,
          onBackTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              _handleLogout();
            }
          },
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: context.horizontalEdgeInsets,
                  child: Column(
                    children: [
                      AppSpacing.lg.h,

                      // Logo
                      Center(
                        child: AppImage.asset(
                          assetPath: Assets.images.appLogo.path,
                          height: 32.wPercent(context),
                          fit: BoxFit.contain,
                        ),
                      ),
                      AppSpacing.colossal.h,

                      // Heading
                      Text(
                        widget.otpType == OtpType.recovery
                            ? context.l10n.forgotPasswordTitle
                            : context.l10n.emailVerificationTitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineLarge?.bold(),
                      ),
                      AppSpacing.sm.h,

                      // Subtitle
                      Text(
                        'Please enter the $_otpLength-digit verification code sent to\n$_targetEmail',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium
                            ?.copyWith(height: 1.4)
                            .colour(context.colors.onSurfaceVariant),
                      ),
                      AppSpacing.xxl.h,

                      // OTP input
                      mui.Material(
                        color: Colors.transparent,
                        child: Pinput(
                          length: _otpLength,
                          controller: _pinController,
                          focusNode: _focusNode,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: submittedPinTheme,
                          showCursor: true,
                          pinputAutovalidateMode:
                              PinputAutovalidateMode.onSubmit,
                          onCompleted: _handleVerifyOtp,
                        ),
                      ),
                      AppSpacing.xxl.h,

                      // Continue button
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _pinController,
                        builder: (context, pinValue, _) {
                          final isPinComplete =
                              pinValue.text.trim().length == _otpLength;
                          return ValueListenableBuilder<bool>(
                            valueListenable: _isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              return AppButton(
                                text: context.l10n.continueButton,
                                isLoading: isLoading,
                                enabled: isPinComplete && !isLoading,
                                onPressed: isPinComplete
                                    ? () => _handleVerifyOtp(pinValue.text)
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                      AppSpacing.md.h,

                      // Resend countdown
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

                      // Logout / Back to Login
                      Center(
                        child: AppButton(
                          type: ButtonType.text,
                          size: ButtonSize.normal,
                          text: widget.otpType == OtpType.recovery
                              ? context.l10n.login
                              : context.l10n.logOut,
                          onPressed: _handleLogout,
                        ),
                      ),
                      AppSpacing.md.h,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
