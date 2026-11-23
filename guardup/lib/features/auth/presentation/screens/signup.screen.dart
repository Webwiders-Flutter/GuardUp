import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
import '/features/auth/domain/repositories/user_repository.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/features/auth/presentation/screens/email_verification.screen.dart';
import '/features/auth/presentation/screens/login.screen.dart';

class SignUpScreen extends StatefulWidget {
  static const route = '/signup';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
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
  final _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoadingNotifier.value) return;

    _isLoadingNotifier.value = true;
    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final role = sl<AuthBloc>().state.sessionRole;

    // Single repository check for active account conflicts (email & phone together in one API call)
    // If account with this email/phone was DELETED, it is freed to use!
    if (sl.isRegistered<UserRepository>()) {
      final conflictError = await sl<UserRepository>()
          .checkRegistrationConflict(
            email: email,
            phone: phone,
            phoneCode: _phoneCountryCode,
          );

      if (conflictError != null) {
        _isLoadingNotifier.value = false;
        if (mounted) {
          AppSnackbar.error(conflictError);
        }
        return;
      }
    }

    sl<AuthBloc>().add(
      AuthSignUpRequested(
        name: name,
        email: email,
        phone: phone,
        phoneCode: _phoneCountryCode,
        password: password,
        role: role,
      ),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!_isLoadingNotifier.value) return;

    if (state.hasError) {
      _isLoadingNotifier.value = false;
      AppSnackbar.error(
        state.errorMessage ?? 'Registration failed. Please try again.',
      );
    } else if (state.operationState.isSuccess) {
      _isLoadingNotifier.value = false;
      final email = _emailController.text.trim().toLowerCase();
      final role = sl<AuthBloc>().state.sessionRole;
      context.push(
        EmailVerificationScreen.route,
        extra: {'email': email, 'role': role},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthStateChanged,
      child: Scaffold(
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
                            onFieldSubmitted: (_) => _handleSignUp(),
                          ),
                          AppSpacing.xl.h,

                          // 8. Sign Up Primary Button (with loading indicator)
                          ValueListenableBuilder<bool>(
                            valueListenable: _isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              return AppButton(
                                text: context.l10n.signUp,
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _handleSignUp,
                              );
                            },
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
      ),
    );
  }
}
