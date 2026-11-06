import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_input_label.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';

/// Screen allowing users to update their account password credentials.
class ChangePasswordScreen extends StatefulWidget {
  static const route = '/change-password';

  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  void _handleUpdatePassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(title: context.l10n.changePasswordTitle),
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
                        color: context.colors.primary.withValues(alpha: 0.4),
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
                        // fillColor: context.colors.onPrimary,
                      ),
                      style: TextStyle(color: context.colors.onSurface),
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validators.password(context, value),
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
                        // fillColor: context.colors.onPrimary,
                      ),
                      style: TextStyle(color: context.colors.onSurface),
                      textInputAction: TextInputAction.next,
                      validator: (value) => Validators.password(context, value),
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
                        // fillColor: context.colors.onPrimary,
                      ),
                      style: TextStyle(color: context.colors.onSurface),
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.confirmPassword(
                        context,
                        value,
                        _newPasswordController.text,
                      ),
                      onFieldSubmitted: (_) => _handleUpdatePassword(),
                    ),
                    AppSpacing.xl.h,

                    // Submit / Update Password Button
                  ],
                ),
              ),
              100.h,
              ValueListenableBuilder<bool>(
                valueListenable: _isLoadingNotifier,
                builder: (context, isLoading, _) {
                  return AppButton(
                    text: context.l10n.updatePassword,

                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleUpdatePassword,
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
