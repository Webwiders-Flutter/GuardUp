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
import '/features/body_guard/presentation/screens/body_guard_complete_profile_screen.dart';
import '/features/company/presentation/screens/company_complete_profile_screen.dart';
import '/features/customer/presentation/screens/customer_home_screen.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_image.dart';

class LoginScreen extends StatelessWidget {
  static const route = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthFormBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(AuthFormState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (state.status.isLoading) return;

    context.read<AuthFormBloc>().add(
      LoginSubmitted(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      ),
    );
  }

  void _showDebugAutofillPicker() {
    AppSheet.show<void>(
      context: context,
      title: 'Debug Autofill',
      subtitle: 'Select role to autofill test credentials',
      action: AppSheetHeaderAction.close,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDebugRoleTile(
            role: 'Customer',
            email: 'amanm.webwiders+customer@gmail.com',
            icon: Icons.person_outline,
          ),
          AppSpacing.sm.h,
          _buildDebugRoleTile(
            role: 'Guard',
            email: 'amanm.webwiders+guard@gmail.com',
            icon: Icons.security,
          ),
          AppSpacing.sm.h,
          _buildDebugRoleTile(
            role: 'Company',
            email: 'amanm.webwiders+company@gmail.com',
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRoleTile({
    required String role,
    required String email,
    required IconData icon,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: context.colors.primary.withValues(alpha: 0.1),
        foregroundColor: context.colors.primary,
        child: Icon(icon, size: 20),
      ),
      title: Text(
        role,
        style: context.textTheme.titleSmall?.bold(),
      ),
      subtitle: Text(
        email,
        style: context.textTheme.bodySmall?.colour(
          context.colors.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        context.pop();
        setState(() {
          _emailController.text = email;
          _passwordController.text = '123456';
        });
        _formKey.currentState?.validate();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthFormBloc, AuthFormState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status.isSuccess) {
          final result = state.status.dataOrNull;
          if (result == AuthFormResult.emailNotConfirmed) {
            final email =
                state.email ?? _emailController.text.trim().toLowerCase();
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

          if (result == AuthFormResult.signedIn) {
            final user = state.authenticatedUser;
            final status = state.effectiveStatus;
            if (status == UserStatus.blocked) {
              AppSnackbar.error(
                'Your account is blocked. Please contact support.',
              );
              context.go(AccountStatusScreen.blockedRoute);
              return;
            }
            AppSnackbar.success('Logged in successfully');
            if (status == UserStatus.incomplete) {
              if (user?.role == UserRole.guard) {
                context.go(BodyGuardCompleteProfileScreen.route);
              } else if (user?.role == UserRole.company) {
                context.go(CompanyCompleteProfileScreen.route);
              }
            } else {
              context.go(CustomerHomeScreen.route);
            }
          }
        } else if (state.status.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.status.errorOrNull,
              fallback: 'Invalid email or password. Please try again.',
            ),
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

                            // 3. Email Field
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
                              onFieldSubmitted: (_) => _handleLogin(state),
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
                            AppButton(
                              text: context.l10n.login,
                              isLoading: isLoading,
                              onPressed: () => _handleLogin(state),
                            ),

                            if (kDebugMode) ...[
                              AppSpacing.md.h,
                              Center(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.colors.primary,
                                    side: BorderSide(
                                      color: context.colors.primary
                                          .withValues(alpha: 0.4),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.bug_report_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Debug Autofill'),
                                  onPressed: _showDebugAutofillPicker,
                                ),
                              ),
                            ],

                            const Spacer(),
                            AppSpacing.xl.h,

                            // 7. Footer: "If you don't have account? Sign Up" via AppRichText
                            Center(
                              child: AppRichText(
                                textAlign: TextAlign.center,
                                spans: [
                                  AppTextSpan(
                                    text: context.l10n.dontHaveAccount,
                                  ),
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
        );
      },
    );
  }
}
