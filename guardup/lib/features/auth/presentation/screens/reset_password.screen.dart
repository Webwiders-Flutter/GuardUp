import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/features/auth/bloc/auth_bloc.dart';
import '/features/auth/bloc/auth_event.dart';
import '/features/auth/bloc/auth_state.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';

class ResetPasswordScreen extends StatefulWidget {
  static const route = '/resetPassword';

  final String? email;

  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  void _handleCancel() {
    sl<AuthBloc>().add(const AuthSignOutRequested());
    context.go(AppRoutes.login);
  }

  void _handleSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoadingNotifier.value) return;

    _isLoadingNotifier.value = true;
    sl<AuthBloc>().add(
      AuthResetPasswordRequested(
        newPassword: _newPasswordController.text.trim(),
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!_isLoadingNotifier.value) return;

    if (state.hasError) {
      _isLoadingNotifier.value = false;
      AppSnackbar.error(
        state.errorMessage ??
            'Failed to reset password. Please try again.',
      );
    } else if (state.operationState.isSuccess) {
      _isLoadingNotifier.value = false;
      AppSnackbar.success(context.l10n.passwordResetSuccessfully);
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      listener: _onAuthStateChanged,
      child: Scaffold(
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                            style: TextStyle(color: context.colors.onSurface),
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
                            style: TextStyle(color: context.colors.onSurface),
                            textInputAction: TextInputAction.done,
                            validator: (value) =>
                                Validators.confirmPassword(
                              context,
                              value,
                              _newPasswordController.text,
                            ),
                            onFieldSubmitted: (_) => _handleSubmit(),
                          ),

                          const Spacer(),
                          AppSpacing.lg.h,

                          // 6. Reset Password Button pinned to bottom
                          ValueListenableBuilder<bool>(
                            valueListenable: _isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              return AppButton(
                                text: context.l10n.resetPassword,
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _handleSubmit,
                              );
                            },
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
      ),
    );
  }
}

