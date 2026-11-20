import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/shared/widgets/feedbacks/widgets/app_snackbar.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_image.dart';
import '/features/body_guard/presentation/screens/body_guard_complete_profile_screen.dart';
import '/features/company/presentation/screens/company_complete_profile_screen.dart';
import '/features/customer/presentation/screens/customer_home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/login';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoadingNotifier.value) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    _isLoadingNotifier.value = true;
    sl<AuthBloc>().add(
      AuthLoginRequested(email: email, password: password),
    );
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!_isLoadingNotifier.value) return;

    if (state.isAuthenticated) {
      _isLoadingNotifier.value = false;
      if (state.isBlocked) {
        AppSnackbar.error('Your account is blocked. Please contact support.');
        context.go(AccountStatusScreen.blockedRoute);
        return;
      }
      AppSnackbar.success('Logged in successfully');
      if (state.requiresOnboarding) {
        if (state.isGuard) {
          context.go(BodyGuardCompleteProfileScreen.route);
        } else if (state.isCompany) {
          context.go(CompanyCompleteProfileScreen.route);
        }
      } else {
        context.go(CustomerHomeScreen.route);
      }
    } else if (state.hasError) {
      _isLoadingNotifier.value = false;
      final errorMsg = state.errorMessage?.toLowerCase() ?? '';
      final isUnconfirmed = state.errorMessage == 'EMAIL_NOT_CONFIRMED' ||
          errorMsg.contains('confirm') ||
          errorMsg.contains('verif') ||
          errorMsg.contains('unconfirmed');

      if (isUnconfirmed) {
        final email = _emailController.text.trim().toLowerCase();
        AppSnackbar.info(
          'Please verify your email address. A 6-digit verification code has been sent.',
        );
        context.push(
          '${EmailVerificationScreen.route}?email=${Uri.encodeComponent(email)}&type=EMAIL',
          extra: <String, dynamic>{
            'email': email,
            'otpType': OtpType.email,
          },
        );
        return;
      }
      AppSnackbar.error(
        state.errorMessage ?? 'Invalid email or password. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
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
                        AppSpacing.huge.h,

                        // GuardUp Logo (Centered)
                        Center(
                          child: AppImage.asset(
                            assetPath: Assets.images.appLogo.path,
                            height: 32.wPercent(context),
                            fit: BoxFit.contain,
                          ),
                        ),
                        AppSpacing.massive.h,

                        // 1. Heading
                        Text(
                          context.l10n.login,
                          style: context.textTheme.headlineLarge?.bold(),
                        ),
                        AppSpacing.xs.h,

                        // 2. Subtitle
                        Text(
                          context.l10n.loginSubtitle,
                          style: context.textTheme.bodyMedium?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.xl.h,

                        // 3. Email / Phone Field
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

                        // 4. Password Field
                        AppTextField.password(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            hintText: '••••••••••••',
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) =>
                              Validators.password(context, value),
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        AppSpacing.xl.h,

                        // 5. Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: AppButton(
                            type: ButtonType.text,
                            size: ButtonSize.normal,
                            text: context.l10n.forgotPassword,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              context.push(ForgotPasswordScreen.route);
                            },
                          ),
                        ),
                        AppSpacing.xl.h,

                        // 6. Login Primary Button
                        ValueListenableBuilder<bool>(
                          valueListenable: _isLoadingNotifier,
                          builder: (context, isLoading, _) {
                            return AppButton(
                              text: context.l10n.login,
                              isLoading: isLoading,
                              onPressed: _handleLogin,
                            );
                          },
                        ),

                        const Spacer(),
                        AppSpacing.xl.h,

                        // 7. Footer: "If you don't have account? Sign Up" via AppRichText
                        Center(
                          child: AppRichText(
                            textAlign: TextAlign.center,
                            spans: [
                              AppTextSpan(text: context.l10n.dontHaveAccount),
                              AppTextSpan(
                                text: context.l10n.signUp,
                                onTap: () {
                                  context.push(SelectRoleScreen.route);
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
