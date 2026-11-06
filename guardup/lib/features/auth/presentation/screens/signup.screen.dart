import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_rich_text.dart';

class SignUpScreen extends StatefulWidget {
  static const route = '/signup';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    // if (!(_formKey.currentState?.validate() ?? false)) return;
    context.push(AppRoutes.emailVerification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        const Spacer(),

                        // 1. Heading
                        Text(
                          context.l10n.signUpTitle,
                          style: context.textTheme.headlineLarge?.bold(),
                        ),
                        AppSpacing.xs.h,

                        // 2. Subtitle
                        Text(
                          context.l10n.signUpSubtitle,
                          style: context.textTheme.bodyMedium?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.xxl.h,

                        // 3. Name Field
                        AppTextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: context.l10n.name,
                          ),
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) => Validators.name(context, value),
                        ),
                        AppSpacing.xl.h,

                        // 4. Phone Number Field
                        AppTextField.phone(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            hintText: context.l10n.phoneNumber,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.phone(context, value),
                        ),
                        AppSpacing.xl.h,

                        // 5. Email Address Field
                        AppTextField.email(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: context.l10n.emailAddress,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.email(context, value),
                        ),
                        AppSpacing.xl.h,

                        // 6. Password Field
                        AppTextField.password(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            hintText: '••••••••••••',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.password(context, value),
                        ),
                        AppSpacing.xl.h,

                        // 7. Confirm Password Field
                        AppTextField.password(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            hintText: '••••••••••••',
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) => Validators.confirmPassword(
                            context,
                            value,
                            _passwordController.text,
                          ),
                          onFieldSubmitted: (_) => _handleSignUp(),
                        ),
                        AppSpacing.xl.h,

                        // 8. Sign Up Primary Button (Has gradient by default)
                        AppButton(
                          text: context.l10n.signUp,

                          onPressed: _handleSignUp,
                        ),

                        const Spacer(),
                        AppSpacing.xl.h,

                        // 9. Footer: "Already have an account? Log in" via AppRichText
                        Center(
                          child: AppRichText(
                            textAlign: TextAlign.center,
                            spans: [
                              AppTextSpan(
                                text: context.l10n.alreadyHaveAccount,
                              ),
                              AppTextSpan(
                                text: context.l10n.login,
                                onTap: () {
                                  context.push(AppRoutes.login);
                                },
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.lg.h,
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
