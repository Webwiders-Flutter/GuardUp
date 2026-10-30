import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/app_fonts.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/utils/validator/validation_functions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/core/widgets/common/custom_app_bar.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        showBackButton: true,
        title: '',
        titleWidget: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.appLogo,
              height: 40,
              width: 40,
              fit: BoxFit.contain,
            ),
            10.width,
            Text(
              context.l10n.forgotPassword,
              style: context.textTheme.headlineMedium?.copyWith(
                color: AppColors.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.defultFont,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              20.height,
              Center(
                child: AppImage(
                  imageUrl: AppAssets.appLogo,
                  height: 160,
                  width: 160,
                  fit: BoxFit.contain,
                  appFileType: AppImageTypes.asset,
                  borderRadius: 0,
                ),
              ),
              40.height,
              AppText(
                type: AppTextType.headlineLarge,
                context.l10n.forgotPassword,
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: AppColors.whiteColor,
              ),
              4.height,
              AppText(
                type: AppTextType.bodySmall,
                context.l10n.welcomeBack,
                color: AppColors.whiteColor,
              ),
              27.height,
              AppTextField(
                controller: emailController,
                hintText: context.l10n.emailHint,
                headingText: context.l10n.emailLabel,
                keyboardType: TextInputType.emailAddress,
                subHeadingText: const AppText(' *', color: Colors.red),
                borderType: AppTextFieldBorderType.outline,
                validator: (password) {
                  return AppValidators.email(
                    password.toString(),
                    context: context,
                  );
                },
                prefix: Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: Image.asset(
                    AppAssets.emailIcon,
                    height: 10,
                    width: 10,
                  ),
                ),
              ),
              40.height,
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthErrorState) {
                    UIFeedback.showSnackbar(
                      context,
                      context.translateFailure(state.message),
                      isError: true,
                    );
                  } else if (state is AuthForgotPasswordSuccessState) {
                    UIFeedback.showSnackbar(
                      context,
                      context.l10n.recoveryEmailSent,
                    );
                    context.push(
                      AppRouter.enterOtp,
                      extra: {
                        'routeName': 'reset_password',
                        'email': emailController.text.trim(),
                      },
                    );
                  }
                },
                builder: (context, state) {
                  return AppButton(
                    buttonColor: AppColors.secondary,
                    text: context.l10n.submit,
                    isLoading: state is AuthLoadingState,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<AuthBloc>().add(
                          AuthForgotPasswordRequested(
                            email: emailController.text.trim(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
