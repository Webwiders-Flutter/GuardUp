import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';

class ForgotPasswordScreen extends StatelessWidget {
  static const route = '/forgotPassword';

  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthFormBloc>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit(AuthFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (state.status.isLoading) return;

    context.read<AuthFormBloc>().add(
      PasswordResetCodeRequested(
        email: _emailController.text.trim().toLowerCase(),
        emailNotFoundFallback: context.l10n.emailNotFound,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthFormBloc, AuthFormState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.status.errorOrNull,
              fallback:
                  'Failed to send password reset code. Please try again.',
            ),
          );
        } else if (state.status.isSuccess &&
            state.status.dataOrNull == AuthFormResult.resetCodeSent) {
          final email =
              state.email ?? _emailController.text.trim().toLowerCase();
          AppSnackbar.info('A verification code has been sent to $email');
          context.push(
            '${EmailVerificationScreen.route}?email=${Uri.encodeComponent(email)}&type=RECOVERY',
            extra: <String, dynamic>{
              'email': email,
              'otpType': OtpType.recovery,
            },
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status.isLoading;

        return Scaffold(
          appBar: AppAppBar.transparent(
            showBackIcon: true,
            onBackTap: () => context.pop(),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: context.horizontalEdgeInsets,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSpacing.lg.h,

                            // 1. GuardUp Logo (Centered)
                            Center(
                              child: AppImage.asset(
                                assetPath: Assets.images.appLogo.path,
                                height: 32.wPercent(context),
                                fit: BoxFit.contain,
                              ),
                            ),
                            AppSpacing.massive.h,

                            // 2. Heading
                            Text(
                              context.l10n.forgotPasswordTitle,
                              style: context.textTheme.headlineLarge?.bold(),
                            ),
                            AppSpacing.xs.h,

                            // 3. Subtitle
                            Text(
                              context.l10n.forgotPasswordSubtitle,
                              style: context.textTheme.bodyMedium?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.xxl.h,

                            // 4. Email Field (Uses default theme styling)
                            AppTextField.email(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: context.l10n.emailAddress,
                              ),
                              textInputAction: TextInputAction.done,
                              validator: (value) =>
                                  Validators.email(context, value),
                              onFieldSubmitted: (_) => _handleSubmit(state),
                            ),

                            const Spacer(),
                            AppSpacing.lg.h,

                            // 5. Submit Button pinned to bottom
                            AppButton(
                              text: context.l10n.submit,
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () => _handleSubmit(state),
                            ),
                            AppSpacing.xl.h,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
