import 'package:flutter/foundation.dart';
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
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_rich_text.dart';

class SignUpScreen extends StatelessWidget {
  static const route = '/signup';

  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthFormBloc>(),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatefulWidget {
  const _SignUpView();

  @override
  State<_SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<_SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(
    text: kDebugMode ? 'Mizan' : '',
  );
  final _phoneController = TextEditingController(
    text: kDebugMode ? '6352416149' : '',
  );
  String _phoneCountryCode = '+91';
  final _emailController = TextEditingController(
    text: kDebugMode ? 'mizan.webwiders@gmail.com' : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? '123456' : '',
  );
  final _confirmPasswordController = TextEditingController(
    text: kDebugMode ? '123456' : '',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp(AuthFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (state.status.isLoading) return;

    final role = context.read<AuthBloc>().state.sessionRole;
    context.read<AuthFormBloc>().add(
      SignUpSubmitted(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        phoneCode: _phoneCountryCode,
        password: _passwordController.text,
        role: role,
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
              fallback: 'Registration failed. Please try again.',
            ),
          );
        } else if (state.status.isSuccess &&
            state.status.dataOrNull == AuthFormResult.signedUp) {
          final email =
              state.email ?? _emailController.text.trim().toLowerCase();
          final role = context.read<AuthBloc>().state.sessionRole;
          context.push(
            EmailVerificationScreen.route,
            extra: {'email': email, 'role': role},
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status.isLoading;

        return Scaffold(
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
                              validator: (value) =>
                                  Validators.name(context, value),
                            ),
                            AppSpacing.xl.h,

                            // 4. Phone Number Field
                            AppTextField.phone(
                              controller: _phoneController,
                              phoneCountryCode: _phoneCountryCode,
                              onCountryCodeChanged: (code) {
                                setState(() {
                                  _phoneCountryCode = code;
                                });
                              },
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
                              onFieldSubmitted: (_) => _handleSignUp(state),
                            ),
                            AppSpacing.xl.h,

                            // 8. Sign Up Primary Button (with loading indicator)
                            AppButton(
                              text: context.l10n.signUp,
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () => _handleSignUp(state),
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
                                      context.push(LoginScreen.route);
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
      },
    );
  }
}
