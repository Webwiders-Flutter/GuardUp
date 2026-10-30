import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/utils/validator/validation_functions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';

import '../../../../core/widgets/common/custom_app_bar.dart';
import '../bloc/auth_bloc.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      appBar: CustomAppBar(
        backgroundColor: Colors.transparent,
        showBackButton:
            false, // User must set a new password since they requested recovery
        titleColor: AppColors.whiteColor,
        title: context.l10n.createNewPasswordTitle,
      ),
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState) {
            UIFeedback.showSnackbar(
              context,
              context.l10n.passwordUpdatedSuccessfully,
            );
            context.go(AppRouter.dashboardScreen);
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
              left: 0,
              right: 0,
              child: Image.asset(
                AppAssets.onboardingImage02,
                fit: BoxFit.contain,
                opacity: const AlwaysStoppedAnimation(0.3),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 100),
                    AppText(
                      type: AppTextType.bodyMedium,
                      context.l10n.pleaseEnterStrongNewPassword,
                      color: AppColors.whiteColor,
                    ),
                    SizedBox(height: 20),
                    AppTextField(
                      controller: newPasswordController,
                      hintText: "***************",
                      headingText: context.l10n.newPassword,
                      keyboardType: TextInputType.visiblePassword,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      isPasswordField: true,
                      validator: (name) {
                        return AppValidators.password(name, context: context);
                      },
                      prefix: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: AppImage(
                          imageUrl: AppAssets.lockIcon,
                          appFileType: AppImageTypes.asset,
                          height: 10,
                          width: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      controller: confirmPasswordController,
                      hintText: "***************",
                      headingText: context.l10n.confirmPassword,
                      isPasswordField: true,
                      keyboardType: TextInputType.visiblePassword,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      validator: (name) {
                        return AppValidators.confirmPassword(
                          name,
                          newPasswordController.text,
                          context: context,
                        );
                      },
                      prefix: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: AppImage(
                          imageUrl: AppAssets.lockIcon,
                          appFileType: AppImageTypes.asset,
                          height: 10,
                          width: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return AppButton(
              height: 50,
              buttonColor: AppColors.secondary,
              textColor: AppColors.blackColor,
              text: context.l10n.save,
              isLoading: state is AuthLoadingState,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<AuthBloc>().add(
                    AuthUpdatePasswordRequested(
                      newPassword: newPasswordController.text,
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
