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
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';

class ResetPasswordScreen extends StatelessWidget {
  static const route = '/resetPassword';

  final String? email;

  const ResetPasswordScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthFormBloc>(),
      child: _ResetPasswordView(email: email),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  final String? email;

  const _ResetPasswordView({this.email});

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
    context.go(LoginScreen.route);
  }

  void _handleSubmit(AuthFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (state.status.isLoading) return;

    context.read<AuthFormBloc>().add(
      NewPasswordSubmitted(newPassword: _newPasswordController.text.trim()),
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
              fallback: 'Failed to reset password. Please try again.',
            ),
          );
        } else if (state.status.isSuccess &&
            state.status.dataOrNull == AuthFormResult.passwordChanged) {
          AppSnackbar.success(context.l10n.passwordResetSuccessfully);
          context.go(LoginScreen.route);
        }
      },
      builder: (context, state) {
        final isLoading = state.status.isLoading;

        return Scaffold(
          appBar: AppAppBar.transparent(
            showBackIcon: true,
            onBackTap: _handleCancel,
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
                              context.l10n.resetPasswordTitle,
                              style: context.textTheme.headlineLarge?.bold(),
                            ),
                            AppSpacing.xs.h,

                            // 3. Subtitle
                            Text(
                              context.l10n.resetPasswordSubtitle,
                              style: context.textTheme.bodyMedium?.colour(
                                context.colors.onSurfaceVariant,
                              ),
                            ),
                            AppSpacing.xxl.h,

                            // 4. New Password Field
                            AppFieldLabel(
                              text: context.l10n.newPassword,
                              isRequired: true,
                            ),
                            AppSpacing.xs.h,
                            AppTextField.password(
                              controller: _newPasswordController,
                              decoration: InputDecoration(
                                hintText: context.l10n.newPassword,
                              ),
                              style: const TextStyle(color: Colors.black),
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  Validators.password(context, value),
                            ),
                            AppSpacing.lg.h,

                            // 5. Confirm Password Field
                            AppFieldLabel(
                              text: context.l10n.confirmPassword,
                              isRequired: true,
                            ),
                            AppSpacing.xs.h,
                            AppTextField.password(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                hintText: context.l10n.confirmPassword,
                              ),
                              style: const TextStyle(color: Colors.black),
                              textInputAction: TextInputAction.done,
                              validator: (value) => Validators.confirmPassword(
                                context,
                                value,
                                _newPasswordController.text,
                              ),
                              onFieldSubmitted: (_) => _handleSubmit(state),
                            ),

                            const Spacer(),
                            AppSpacing.lg.h,

                            // 6. Reset Password Button pinned to bottom
                            AppButton(
                              text: context.l10n.resetPassword,
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
