import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_textfield/app_textfield.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showPasswordStep = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.mainBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.greyColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.deleteAccount,
                style: const TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (!_showPasswordStep) ...[
                Text(
                  context.l10n.deleteAccountConfirmation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.headingTextFieldColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        text: context.l10n.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildButton(
                        text: context.l10n.next,
                        onPressed: () {
                          setState(() {
                            _showPasswordStep = true;
                          });
                        },
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  context.l10n.deleteAccountPasswordConfirmation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.headingTextFieldColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _passwordController,
                  hintText: context.l10n.passwordHint,
                  headingText: context.l10n.passwordLabel,
                  isPasswordField: true,
                  textColor: Colors.white,
                  fillColor: AppColors.color132030,
                  borderColor: AppColors.greyColor,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.validationPasswordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        text: context.l10n.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return _buildButton(
                            text: context.l10n.deleteAccount,
                            isLoading:
                                state is AuthLoadingState ||
                                state is AuthDeleteAccountLoadingState,
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                context.read<AuthBloc>().add(
                                  AuthDeleteAccountRequested(
                                    password: _passwordController.text,
                                  ),
                                );
                                // The dialog will be handled by the listener in ProfileScreen
                              }
                            },
                            color: Colors.red,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    bool isOutlined = false,
    bool isLoading = false,
    Color? color,
  }) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isOutlined
            ? null
            : (color ?? AppColors.primary).withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color ?? AppColors.greyColor),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.red,
              ),
            )
          : Text(text, style: TextStyle(color: color ?? AppColors.whiteColor)),
    );
  }
}
