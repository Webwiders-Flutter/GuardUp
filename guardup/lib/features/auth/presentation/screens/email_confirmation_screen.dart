import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/pinput_field/pinput_field_widget.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

class EmailConfirmationScreen extends StatefulWidget {
  final String? email;
  const EmailConfirmationScreen({super.key, this.email});

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _start = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _verifyOtp() {
    final token = _otpController.text.trim();
    if (token.length != 6) {
      UIFeedback.showSnackbar(
        context,
        context.l10n.pleaseEnter6DigitCode,
        isError: true,
      );
      return;
    }
    if (widget.email == null || widget.email!.isEmpty) {
      UIFeedback.showSnackbar(
        context,
        context.l10n.emailAddressNotFound,
        isError: true,
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthVerifySignupEmailRequested(email: widget.email!, token: token),
    );
  }

  void _resendEmail() {
    if (widget.email == null || widget.email!.isEmpty) {
      UIFeedback.showSnackbar(
        context,
        context.l10n.emailAddressNotFound,
        isError: true,
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthResendSignupEmailRequested(email: widget.email!),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthVerifySignupEmailSuccessState) {
          UIFeedback.showSnackbar(context, context.l10n.emailVerifiedSuccess);
          context.read<AuthBloc>().add(const AuthRefreshEvent());
          context.go(AppRouter.dashboardScreen);
        } else if (state is AuthResendSignupEmailSuccessState) {
          UIFeedback.showSnackbar(
            context,
            context.l10n.verificationEmailSentSuccessfully,
          );
          _startTimer();
        } else if (state is AuthErrorState) {
          UIFeedback.showSnackbar(
            context,
            context.translateFailure(state.message),
            isError: true,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoadingState;

        return Scaffold(
          backgroundColor: AppColors.mainBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                20.height,
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: AppColors.secondary,
                ),
                24.height,
                AppText(
                  context.l10n.verifyYourEmail,
                  type: AppTextType.bodyMedium,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                  textAlign: TextAlign.center,
                ),
                12.height,
                AppText(
                  context.l10n.weHaveSentVerificationLink(
                    widget.email ?? context.l10n.yourEmailAddress,
                  ),
                  type: AppTextType.bodySmall,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.headingTextFieldColor,
                  textAlign: TextAlign.center,
                ),
                32.height,
                AppText(
                  context.l10n.tapLinkOrEnterCode,
                  type: AppTextType.bodySmall,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.whiteColor,
                  textAlign: TextAlign.center,
                ),
                16.height,
                PinputFieldWidget(pinController: _otpController, length: 6),
                24.height,
                AppButton(
                  height: 50,
                  buttonColor: AppColors.secondary,
                  text: context.l10n.verify,
                  textColor: AppColors.blackColor,
                  isLoading: isLoading,
                  onPressed: _verifyOtp,
                ),
                16.height,
                AppButton(
                  height: 50,
                  buttonColor: _canResend
                      ? AppColors.whiteColor
                      : AppColors.greyColor,
                  text: _canResend
                      ? context.l10n.resendEmail
                      : context.l10n.resendEmailIn(_start),
                  textColor: AppColors.blackColor,
                  isLoading: isLoading && _canResend,
                  onPressed: _canResend ? _resendEmail : () {},
                ),
                12.height,
                TextButton(
                  onPressed: () {
                    context.go(AppRouter.login);
                  },
                  child: AppText(
                    context.l10n.goToLogin,
                    type: AppTextType.bodySmall,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                40.height,
              ],
            ),
          ),
        );
      },
    );
  }
}
