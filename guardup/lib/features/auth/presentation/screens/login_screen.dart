import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/utils/validator/validation_functions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/core/widgets/common/custom_ritch_text.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/common/custom_app_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPhoneOtpRequested = false;
  final TextEditingController passwordController = TextEditingController(
    text: kDebugMode ? "123456" : "",
  );
  final TextEditingController emailController = TextEditingController(
    text: kDebugMode ? "rajkumar.webwiders@gmail.com" : "",
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: emailController.text,
          password: passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        backgroundColor: Colors.transparent,
        showBackButton: context.canPop(),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            final user = state.user;

            if (!user.isPhoneVerified &&
                user.phone != null &&
                user.phone!.isNotEmpty) {
              if (!_isPhoneOtpRequested) {
                _isPhoneOtpRequested = true;
                context.read<AuthBloc>().add(
                  AuthUpdatePhoneRequested(
                    newPhone: user.phone!,
                    phoneCode: user.phoneCode ?? '',
                    countryCode: user.countryCode ?? '',
                  ),
                );
              }
            } else {
              context.go(AppRouter.dashboardScreen);
            }
          } else if (state is AuthUpdatePhoneOtpSentState) {
            context.pushNamed(
              AppRouter.enterOtp,
              extra: {
                'routeName': 'verify_signup_phone',
                'email': state.phone,
                'phoneCode': state.phoneCode,
                'countryCode': state.countryCode,
              },
            );
          } else if (state is AuthEmailNotConfirmedState) {
            context.go(
              '${AppRouter.emailConfirmation}?email=${emailController.text}',
            );
          } else if (state is AuthErrorState) {
            UIFeedback.showSnackbar(
              context,
              context.translateFailure(state.message),
              isError: true,
            );
          }
        },
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: Stack(
              children: [
                // Background image
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Image.asset(
                      AppAssets.onboardingImage02,
                      height: 181,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),

                // Scrollable content
                Positioned.fill(
                  child: SingleChildScrollView(
                    // keyboardDismissBehavior:
                    //     ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          height: 137,
                          width: 165,
                          fit: BoxFit.contain,
                          AppAssets.appLogo,
                        ),

                        const SizedBox(height: 30),

                        AppText(
                          textAlign: TextAlign.center,
                          type: AppTextType.bodyMedium,
                          context.l10n.welcomeBack,
                          fontSize: 25,
                          fontWeight: FontWeight.w400,
                          color: AppColors.whiteColor,
                        ),

                        const SizedBox(height: 4),

                        AppText(
                          textAlign: TextAlign.center,
                          type: AppTextType.bodySmall,
                          context.l10n.loginToContinue,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.headingTextFieldColor,
                        ),

                        const SizedBox(height: 42),

                        AppTextField(
                          controller: emailController,
                          hintText: context.l10n.emailHint,
                          borderColor: Colors.transparent,
                          headingText: context.l10n.emailLabel,
                          keyboardType: TextInputType.emailAddress,
                          subHeadingText: AppText(' *', color: Colors.red),
                          borderType: AppTextFieldBorderType.outline,
                          validator: (email) {
                            return AppValidators.email(
                              email.toString(),
                              context: context,
                            );
                          },
                          prefix: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Image.asset(
                              AppAssets.emailIcon,
                              height: 10,
                              width: 10,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        AppTextField(
                          controller: passwordController,
                          hintText: context.l10n.passwordHint,
                          borderColor: Colors.transparent,
                          headingText: context.l10n.passwordLabel,
                          keyboardType: TextInputType.visiblePassword,
                          subHeadingText: AppText(' *', color: Colors.red),
                          borderType: AppTextFieldBorderType.outline,
                          isPasswordField: true,
                          validator: (password) {
                            return AppValidators.password(
                              password.toString(),
                              context: context,
                            );
                          },
                          prefix: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Image.asset(
                              AppAssets.lockIcon,
                              height: 10,
                              width: 10,
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onSubmit(),
                        ),

                        const SizedBox(height: 8),

                        GestureDetector(
                          onTap: () {
                            context.push(AppRouter.forgotPasswordScreen);
                          },
                          child: AppText(
                            textAlign: TextAlign.end,
                            type: AppTextType.bodySmall,
                            context.l10n.forgotPassword,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.headingTextFieldColor,
                          ),
                        ),

                        const SizedBox(height: 25),

                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return AppButton(
                              height: 50,
                              buttonColor: AppColors.secondary,
                              text: context.l10n.logIn,
                              textColor: AppColors.blackColor,
                              isLoading: state is AuthLoadingState,
                              onPressed: _onSubmit,
                            );
                          },
                        ),

                        const SizedBox(height: 110),

                        CustomRichText(
                          textAlign: TextAlign.center,
                          firstText: context.l10n.dontHaveAnAccount,
                          secondText: context.l10n.signup,
                          firstFontSize: 14,
                          secondFontSize: 14,
                          firstColor: AppColors.headingTextFieldColor,
                          secondColor: AppColors.secondary,
                          secondUnderline: true,
                          secondUnderlineColor: AppColors.secondary,
                          onSecondTap: () {
                            context.pushReplacement(AppRouter.signup);
                          },
                        ),

                        // Extra bottom space so background doesn't cover content
                        // const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
