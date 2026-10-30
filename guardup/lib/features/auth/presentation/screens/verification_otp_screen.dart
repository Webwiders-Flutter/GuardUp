import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/core/widgets/common/custom_ritch_text.dart';
import 'package:guardup/core/widgets/pinput_field/pinput_field_widget.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

class VerificationOtpScreen extends StatefulWidget {
  final String? routeName;
  final String? email;
  final String? phoneCode;
  final String? countryCode;

  const VerificationOtpScreen({
    super.key,
    this.routeName,
    this.email,
    this.phoneCode,
    this.countryCode,
  });

  @override
  State<VerificationOtpScreen> createState() => _VerificationOtpScreenState();
}

class _VerificationOtpScreenState extends State<VerificationOtpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController pinController;
  Timer? _timer;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    pinController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onVerify() {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.routeName == "change_email") {
        context.read<AuthBloc>().add(
          AuthVerifyEmailUpdateRequested(
            email: widget.email!,
            token: pinController.text,
          ),
        );
      } else if (widget.routeName == "change_phone") {
        context.read<AuthBloc>().add(
          AuthVerifyPhoneUpdateRequested(
            phone: widget
                .email!, // Email variable is acting as the generic identifier
            token: pinController.text,
            phoneCode: widget.phoneCode!,
            countryCode: widget.countryCode!,
          ),
        );
      } else if (widget.routeName == "verify_signup_phone") {
        context.read<AuthBloc>().add(
          AuthVerifySignupPhoneRequested(
            phone: widget.email!,
            token: pinController.text,
            phoneCode: widget.phoneCode!,
            countryCode: widget.countryCode!,
          ),
        );
      } else if (widget.routeName == "reset_password") {
        context.read<AuthBloc>().add(
          AuthVerifyPasswordRecoveryOtpRequested(
            email: widget.email!,
            token: pinController.text.trim(),
          ),
        );
      } else if (widget.routeName == "verify_signup_email") {
        context.read<AuthBloc>().add(
          AuthVerifySignupEmailRequested(
            email: widget.email!,
            token: pinController.text.trim(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthVerifyPasswordRecoveryOtpSuccessState) {
          UIFeedback.showSnackbar(context, context.l10n.success);
          context.pushReplacementNamed(AppRouter.createNewPassword);
        } else if (state is AuthVerifySignupEmailSuccessState) {
          UIFeedback.showSnackbar(context, context.l10n.emailVerifiedSuccess);
          context.read<AuthBloc>().add(const AuthRefreshEvent());
          context.go(AppRouter.dashboardScreen);
        } else if (state is AuthVerifySignupPhoneSuccessState ||
            state is AuthUpdateEmailSuccessState ||
            state is AuthUpdatePhoneSuccessState) {
          UIFeedback.showSnackbar(
            context,
            state is AuthVerifySignupPhoneSuccessState
                ? context.l10n.phoneVerifiedSuccess
                : context.l10n.success,
          );
          context.read<AuthBloc>().add(const AuthRefreshEvent());
          context.go(AppRouter.dashboardScreen);
        } else if (state is AuthUpdateEmailOtpSentState ||
            state is AuthUpdatePhoneOtpSentState ||
            state is AuthForgotPasswordSuccessState ||
            state is AuthResendSignupEmailSuccessState) {
          bool isResend = false;
          if (state is AuthUpdateEmailOtpSentState) {
            isResend = state.isResend;
          }
          if (isResend ||
              state is AuthForgotPasswordSuccessState ||
              state is AuthResendSignupEmailSuccessState) {
            UIFeedback.showSnackbar(context, context.l10n.success);
          } else if (state is AuthUpdatePhoneOtpSentState) {
            UIFeedback.showSnackbar(context, context.l10n.success);
          }
        } else if (state is AuthErrorState) {
          AppLogs.error('Change auth info error: ${state.message}');
          UIFeedback.showSnackbar(
            context,
            context.translateFailure(state.message),
            isError: true,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackgroundColor,
        appBar: CustomAppBar(
          backgroundColor: AppColors.primary,
          showBackButton: true,
          title: context.l10n.verify,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                20.height,
                Center(
                  child: AppImage(
                    imageUrl: AppAssets.appLogo,
                    height: 120,
                    width: 165,
                    backgroundColor: Colors.transparent,
                    fit: BoxFit.contain,
                    appFileType: AppImageTypes.asset,
                    borderRadius: 0,
                  ),
                ),
                30.height,
                AppText(
                  textAlign: TextAlign.center,
                  type: AppTextType.headlineLarge,
                  context.l10n.enterVerificationCode,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppColors.whiteColor,
                ),
                8.height,
                AppText(
                  (widget.routeName == 'change_phone' ||
                          widget.routeName == 'verify_signup_phone')
                      ? context.l10n.checkPhoneForCode
                      : context.l10n.checkEmailForCode,
                  textAlign: TextAlign.center,
                  color: Colors.white60,
                  fontSize: 13,
                ),
                8.height,
                CustomRichText(
                  firstText: context.l10n.verificationFor,
                  secondText: "${widget.email ?? context.l10n.yourEmail} ",
                  thirdText: "",
                  textAlign: TextAlign.center,
                  firstFontSize: 13,
                  secondFontSize: 13,
                  thirdFontSize: 13,
                  firstColor: Colors.white60,
                  secondColor: AppColors.primary,
                  thirdColor: AppColors.whiteColor,
                ),
                30.height,
                PinputFieldWidget(pinController: pinController, length: 6),
                20.height,
                if (_remainingSeconds > 0)
                  AppText(
                    _formatTime(_remainingSeconds),
                    color: AppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                30.height,
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return AppButton(
                      height: 50,
                      isLoading: state is AuthLoadingState,
                      buttonColor: AppColors.secondary,
                      textColor: AppColors.blackColor,
                      text: context.l10n.verify,
                      onPressed: _onVerify,
                    );
                  },
                ),
                if (_remainingSeconds == 0) ...[
                  30.height,
                  CustomRichText(
                    textAlign: TextAlign.center,
                    firstText: "${context.l10n.didNotReceiveCode} ",
                    secondText: context.l10n.resendCodeTitle,
                    firstFontSize: 14,
                    secondFontSize: 14,
                    firstColor: AppColors.whiteColor,
                    secondColor: AppColors.primary,
                    secondUnderline: true,
                    secondUnderlineColor: AppColors.primary,
                    onSecondTap: () {
                      if (_remainingSeconds == 0 && widget.email != null) {
                        if (widget.routeName == "reset_password") {
                          context.read<AuthBloc>().add(
                            AuthForgotPasswordRequested(email: widget.email!),
                          );
                        } else if (widget.routeName == "verify_signup_email") {
                          context.read<AuthBloc>().add(
                            AuthResendSignupEmailRequested(
                              email: widget.email!,
                            ),
                          );
                        } else {
                          context.read<AuthBloc>().add(
                            AuthUpdateEmailRequested(
                              newEmail: widget.email!,
                              isResend: true,
                            ),
                          );
                        }
                        _startTimer();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
