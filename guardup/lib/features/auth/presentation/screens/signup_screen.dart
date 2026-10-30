import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/app_constants.dart';
import 'package:guardup/core/services/country_detector_service.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/utils/validator/validation_functions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_check_box/app_check_box.dart';
import 'package:guardup/core/widgets/app_phone_textfield/app_phone_textfield.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/core/widgets/common/custom_ritch_text.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController(
    text: kDebugMode ? "Raj kumar Patel" : "",
  );
  final TextEditingController phoneController = TextEditingController(
    text: kDebugMode ? "9977783414" : "",
  );
  final TextEditingController passwordController = TextEditingController(
    text: kDebugMode ? "123456" : "",
  );
  final TextEditingController emailController = TextEditingController(
    text: kDebugMode ? "rajkumar.webwiders@gmail.com" : "",
  );
  final TextEditingController confirmPasswordController = TextEditingController(
    text: kDebugMode ? "123456" : "",
  );
  String _selectedCountryCode = AppConstants.defaultCountryCode;
  String _selectedPhoneCode = AppConstants.defaultPhoneCode;

  @override
  void initState() {
    super.initState();
    _detectCountryCode();
  }

  Future<void> _detectCountryCode() async {
    final country = await CountryDetectorService.detectCountryWithPhoneCode();
    if (country != null && mounted) {
      setState(() {
        _selectedCountryCode = country.countryCode;
        _selectedPhoneCode = country.phoneCode;
      });
    }
  }

  final ValueNotifier<bool> isChecked = ValueNotifier(false);

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      if (!isChecked.value) {
        UIFeedback.showSnackbar(
          context,
          context.l10n.acceptTermsCondition,
          isError: true,
        );
        return;
      }
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: emailController.text,
          password: passwordController.text,
          name: nameController.text,
          phone: phoneController.text,
          phoneCode: _selectedPhoneCode,
          countryCode: _selectedCountryCode,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthEmailNotConfirmedState) {
            UIFeedback.showSnackbar(
              context,
              context.l10n.signUpSuccessCheckInbox,
              isError: false,
            );
            context.push(
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
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              child: Image.asset(
                height: 181,
                fit: BoxFit.contain,
                AppAssets.onboardingImage02,
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 50),
                    AppText(
                      textAlign: TextAlign.center,
                      type: AppTextType.bodyMedium,
                      context.l10n.createAccount,
                      fontSize: 25,
                      fontWeight: FontWeight.w400,
                      color: AppColors.whiteColor,
                    ),
                    SizedBox(height: 4),
                    AppText(
                      textAlign: TextAlign.center,
                      type: AppTextType.bodySmall,
                      context.l10n.joinSkyvioraToday,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.headingTextFieldColor,
                    ),
                    SizedBox(height: 25),
                    AppTextField(
                      controller: nameController,
                      hintText: context.l10n.nameHint,
                      borderColor: Colors.transparent,
                      headingText: context.l10n.nameLabel,
                      keyboardType: TextInputType.text,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      validator: (name) {
                        return AppValidators.name(name, context: context);
                      },
                      prefix: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Image.asset(
                          AppAssets.userIcon,
                          height: 10,
                          width: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    AppPhoneField(
                      borderColor: Colors.transparent,
                      controller: phoneController,
                      initialCountryCode: _selectedCountryCode,
                      onCountryChanged: (country) {
                        _selectedCountryCode = country.countryCode;
                        _selectedPhoneCode = country.phoneCode;
                      },
                      hintText: context.l10n.mobileNumberHint,
                      headingText: context.l10n.mobileNumber,
                      keyboardType: TextInputType.number,
                      subHeadWidget: AppText(' *', color: Colors.red),
                    ),

                    SizedBox(height: 16),
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
                        padding: const EdgeInsets.all(14.0),
                        child: Image.asset(
                          AppAssets.emailIcon,
                          height: 10,
                          width: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
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
                        padding: const EdgeInsets.all(13.0),
                        child: Image.asset(
                          AppAssets.lockIcon,
                          height: 10,
                          width: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      controller: confirmPasswordController,
                      hintText: context.l10n.passwordHint,
                      borderColor: Colors.transparent,
                      headingText: context.l10n.confirmPassword,
                      keyboardType: TextInputType.visiblePassword,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      isPasswordField: true,
                      validator: (password) {
                        return AppValidators.confirmPassword(
                          password?.toString(),
                          passwordController.text,
                          context: context,
                        );
                      },
                      prefix: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Image.asset(
                          AppAssets.lockIcon,
                          height: 10,
                          width: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSubmit(),
                    ),

                    SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: isChecked,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.9,
                              child: CustomCheckBox(
                                value: value,
                                onChanged: (valueChanged) {
                                  isChecked.value = valueChanged!;
                                },
                              ),
                            );
                          },
                        ),
                        12.width,
                        Flexible(
                          child: CustomRichText(
                            firstText: context.l10n.haveReviewedAndAgree,
                            firstColor: AppColors.headingTextFieldColor,
                            onSecondTap: () {
                              context.push(AppRouter.termsAndConditionScreen);
                            },
                            onFourthTap: () {
                              context.push(AppRouter.privacyPolicyScreen);
                            },
                            secondText: context.l10n.termsOfUse,
                            secondColor: AppColors.whiteColor,
                            secondFontSize: 14,
                            secondUnderline: true,
                            secondUnderlineColor: AppColors.whiteColor,
                            thirdText: context.l10n.andText,
                            thirdColor: AppColors.headingTextFieldColor,
                            fourthText: context.l10n.privacyPolicy,
                            fourthColor: AppColors.whiteColor,
                            fourthUnderline: true,
                            fourthFontSize: 14,
                            fifthUnderlineColor: AppColors.whiteColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return AppButton(
                          height: 50,
                          buttonColor: AppColors.secondary,
                          text: context.l10n.signup,
                          textColor: AppColors.blackColor,
                          isLoading: state is AuthLoadingState,
                          onPressed: _onSubmit,
                        );
                      },
                    ),
                    SizedBox(height: 25),
                    CustomRichText(
                      textAlign: TextAlign.center,
                      firstText: context.l10n.alreadyHaveAnAccount,
                      secondText: context.l10n.logIn,
                      firstFontSize: 14,
                      secondFontSize: 14,
                      firstColor: AppColors.headingTextFieldColor,
                      secondColor: AppColors.secondary,
                      secondUnderline: true,
                      secondUnderlineColor: AppColors.secondary,
                      onSecondTap: () {
                        context.pushReplacement(AppRouter.login);
                      },
                    ),
                    SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
