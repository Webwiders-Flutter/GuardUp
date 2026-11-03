import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _oldPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleUpdatePassword() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    AppSnackbar.success(
      context.l10n.passwordChangedSuccessfully,
      context: context,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: context.l10n.changePasswordTitle,
        centerTitle: true,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSpacing.xl.h,

                        // 1. Old Password Field
                        AppTextField.password(
                          controller: _oldPasswordController,
                          hintText: context.l10n.oldPassword,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.password(context, value),
                        ),
                        AppSpacing.md.h,

                        // 2. New Password Field
                        AppTextField.password(
                          controller: _newPasswordController,
                          hintText: context.l10n.newPassword,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.password(context, value),
                        ),
                        AppSpacing.md.h,

                        // 3. Confirm Password Field
                        AppTextField.password(
                          controller: _confirmPasswordController,
                          hintText: context.l10n.confirmPassword,
                          textInputAction: TextInputAction.done,
                          validator: (value) => Validators.confirmPassword(
                            context,
                            value,
                            _newPasswordController.text,
                          ),
                          onFieldSubmitted: (_) => _handleUpdatePassword(),
                        ),

                        const Spacer(),
                        AppSpacing.lg.h,

                        // 4. Update Password Button
                        AppButton(
                          text: context.l10n.updatePassword,
                          size: ButtonSize.large,
                          onPressed: _handleUpdatePassword,
                        ),
                        AppSpacing.huge.h,
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
  }
}
