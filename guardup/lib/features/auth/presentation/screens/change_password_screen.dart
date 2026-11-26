import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/di/injection_container.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/features/auth/auth.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Screen allowing users to update their account password credentials.
class ChangePasswordScreen extends StatelessWidget {
  static const route = '/change-password';

  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountBloc>(),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  const _ChangePasswordView();

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _formKey = GlobalKey<FormState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleUpdatePassword(AccountState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (state.status.isLoading) return;

    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    context.read<AccountBloc>().add(
      AccountPasswordChanged(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status.isSuccess &&
            state.status.dataOrNull == AccountAction.passwordChanged) {
          AppSnackbar.success('Password updated successfully.');
          context.pop();
        } else if (state.status.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.status.errorOrNull,
              fallback: 'Failed to update password',
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status.isLoading;

        return Scaffold(
          appBar: AppAppBar.transparent(
            title: context.l10n.changePasswordTitle,
            fontSize: 14,
          ),
          body: SingleChildScrollView(
            padding: context.horizontalEdgeInsets,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.xl.h,

                  // 1. Upper Info Card
                  WrapperCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        QuickContainer(
                          w: 48,
                          h: 48,
                          shape: QuickContainerShape.circle,
                          color: context.colors.primaryContainer.withValues(
                            alpha: 0.35,
                          ),
                          border: Border.all(
                            color: context.colors.primary.withValues(
                              alpha: 0.4,
                            ),
                            width: 1.5,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.lock_reset_rounded,
                            color: context.colors.primary,
                            size: AppSizes.iconLg,
                          ),
                        ),
                        AppSpacing.md.w,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.changePasswordTitle,
                                style: context.textTheme.titleMedium?.bold(),
                              ),
                              AppSpacing.xxs.h,
                              Text(
                                'Update your security credentials to keep your account safe.',
                                style: context.textTheme.bodySmall?.colour(
                                  context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.lg.h,

                  // 2. Form Fields
                  WrapperCard(
                    borderColor: context.colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Old Password Field
                        AppFieldLabel(
                          text: context.l10n.oldPassword,
                          isRequired: true,
                        ),
                        AppSpacing.xs.h,
                        AppTextField.password(
                          controller: _oldPasswordController,
                          decoration: InputDecoration(
                            hintText: context.l10n.oldPassword,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.password(context, value),
                        ),
                        AppSpacing.lg.h,

                        // New Password Field
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
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.password(context, value),
                        ),
                        AppSpacing.lg.h,

                        // Confirm Password Field
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
                          textInputAction: TextInputAction.done,
                          validator: (value) => Validators.confirmPassword(
                            context,
                            value,
                            _newPasswordController.text,
                          ),
                          onFieldSubmitted: (_) => _handleUpdatePassword(state),
                        ),
                        AppSpacing.xl.h,
                      ],
                    ),
                  ),
                  100.h,
                  AppButton(
                    text: context.l10n.updatePassword,
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () => _handleUpdatePassword(state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
