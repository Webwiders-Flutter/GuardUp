import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

import '../../../../core/utils/app_router.dart';
import '../../../../core/widgets/common/custom_app_bar.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  void _onChangeEmail() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthUpdateEmailRequested(newEmail: emailController.text.trim()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      emailController.text = authState.user.email;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
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
        } else if (state is AuthUpdateEmailOtpSentState && !state.isResend) {
          context.push(
            AppRouter.enterOtp,
            extra: {'routeName': 'change_email', 'email': state.email},
          );
        } else if (state is AuthUpdateEmailSuccessState) {
          // UIFeedback.showSnackbar(context, context.l10n.success);
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBackgroundColor,
        appBar: CustomAppBar(
          backgroundColor: Colors.transparent,
          showBackButton: true,
          titleColor: AppColors.whiteColor,
          title: context.l10n.changeEmail,
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
                      title: context.l10n.changeEmail,
                      subtitle: context.l10n.changeEmailSubtitle,
                    ),
                    AppTextField(
                      controller: emailController,
                      hintText: context.l10n.exampleEmailCom,
                      headingText: context.l10n.newEmailLabel,
                      keyboardType: TextInputType.emailAddress,
                      subHeadingText: AppText(' *', color: Colors.red),
                      borderType: AppTextFieldBorderType.outline,
                      validator: (email) =>
                          AppValidators.email(email, context: context),
                      prefix: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: AppImage(
                          imageUrl: AppAssets.emailIcon,
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
                onPressed: _onChangeEmail,
              );
            },
          ),
        ),
      ),
    );
  }
}
