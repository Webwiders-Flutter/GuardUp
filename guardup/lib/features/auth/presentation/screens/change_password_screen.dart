import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/core/utils/validator/validation_functions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardup/features/auth/presentation/widgets/auth_header_widget.dart';

import '../../../../core/widgets/common/custom_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController(
    text: "",
  );
  final TextEditingController confirmPasswordController =
      TextEditingController();

  void _onChangePassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthUpdatePasswordRequested(
          newPassword: newPasswordController.text,
          oldPassword: oldPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthErrorState) {
          UIFeedback.showSnackbar(
            context,
            context.translateFailure(state.message),
            isError: true,
          );
        } else if (state is AuthUpdatePasswordSuccessState) {
          UIFeedback.showSnackbar(
            context,
            context.l10n.passwordUpdatedSuccessfully,
          );
          // if (context.canPop()) {
          //   context.pop();
          // } else {
          //   context.go(AppRouter.dashboardScreen);
          // }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackgroundColor,
        appBar: CustomAppBar(
          backgroundColor: Colors.transparent,
          showBackButton: true,
          titleColor: AppColors.whiteColor,
          title: context.l10n.changePassword,
        ),
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        body: Stack(
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
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeaderWidget(
                      title: context.l10n.changePassword,
                      subtitle: context.l10n.changePasswordSubtitle,
                    ),
                    AppTextField(
                      controller: oldPasswordController,
                      hintText: "***************",
                      headingText: context.l10n.oldPassword,
                      keyboardType: TextInputType.visiblePassword,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      isPasswordField: true,
                      validator: (name) =>
                          AppValidators.password(name, context: context),
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
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: newPasswordController,
                      hintText: "***************",
                      headingText: context.l10n.newPassword,
                      keyboardType: TextInputType.visiblePassword,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      isPasswordField: true,
                      validator: (name) {
                        if (name != null &&
                            name == oldPasswordController.text) {
                          return context.l10n.newPasswordMustBeDifferent;
                        }
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
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: confirmPasswordController,
                      hintText: "***************",
                      headingText: context.l10n.confirmPassword,
                      isPasswordField: true,
                      keyboardType: TextInputType.visiblePassword,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      validator: (name) => AppValidators.confirmPassword(
                        name,
                        newPasswordController.text,
                        context: context,
                      ),
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 40, left: 16, right: 16),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return AppButton(
                height: 50,
                isLoading: state is AuthLoadingState,
                buttonColor: AppColors.secondary,
                textColor: AppColors.blackColor,
                text: context.l10n.save,
                onPressed: _onChangePassword,
              );
            },
          ),
        ),
      ),
    );
  }
}
