import 'package:flutter/foundation.dart';

import '/core/services/notification/push_notification_service.dart';
import '/core/extensions/riverpod.extension.dart';
import '/features/auth/di/auth.providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_regx.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';
import '/shared/controllers/selection.controller.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final SelectionController<String> _rememberMeController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _rememberMeController = SelectionController<String>(['remember']);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _rememberMeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // On Web, request notification permission during this direct user click gesture

    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

    if (!mounted) return;

    final ok = ref
        .read(authControllerProvider)
        .handleResult(
          showSuccess: false,
          fallbackErrorMessage: 'Something went wrong',
        );

    if (ok) {
      if (kIsWeb) {
        try {
          final isAuthorized =
              await PushNotificationService.isNotificationAuthorized;
          if (!isAuthorized) {
            await PushNotificationService.requestPermission();
          }
        } catch (_) {}
      }
      if (mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  // void _onForgotPasswordClick() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xxl,
            ),
            child: QuickContainer(
              maxW: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBrandHeader(),
                  AppSpacing.xl.h,
                  _buildFormCard(),
                  AppSpacing.xl.h,
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Brand Header ───────────────────────────────────────────────────────────

  Widget _buildBrandHeader() {
    return Column(
      children: [
        QuickContainer(
          w: (AppSpacing.xxl * 2) + AppSpacing.xs,
          h: (AppSpacing.xxl * 2) + AppSpacing.xs,
          radius: AppRadius.md + 2,
          color: context.colors.primary,
          border: Border.all(
            color: context.colors.borderDark.withValues(alpha: 0.3),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.security_rounded,
            color: context.colors.onPrimary,
            size: AppSpacing.xxl + 2,
          ),
        ),
        AppSpacing.md.h,
        Text(
          'GuardUp Admin',
          style: context.textTheme.titleLarge
              ?.bold()
              .size(AppSpacing.xl)
              .textSpacing(-0.3),
        ),
        AppSpacing.xs.h,
        Text(
          'Executive Protection Administration',
          style: context.textTheme.bodySmall
              ?.colour(context.colors.onSurfaceSecondary)
              .size(AppSpacing.md + 0.5),
        ),
      ],
    );
  }

  // ── Main Authentication Card ───────────────────────────────────────────────

  Widget _buildFormCard() {
    return QuickContainer(
      p: AppSpacing.xxl,
      color: context.colors.surface,
      radius: AppRadius.md,
      border: Border.all(
        color: context.colors.borderLight.withValues(alpha: 0.7),
      ),
      shadows: [
        BoxShadow(
          color: context.colors.black.withValues(alpha: 0.03),
          blurRadius: AppSpacing.lg + 2,
          offset: const Offset(0, 4),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign In',
              style: context.textTheme.titleMedium?.bold().size(
                AppSpacing.lg + 1,
              ),
            ),
            AppSpacing.xs.h,
            Text(
              'Enter your registered credentials to access the console',
              style: context.textTheme.bodySmall
                  ?.colour(context.colors.onSurfaceSecondary)
                  .size(AppSpacing.md + 0.5),
            ),
            AppSpacing.xl.h,

            // Email
            const AppFieldLabel(text: 'Email Address', isRequired: true),
            AppSpacing.xs.h,
            AppTextField.email(
              controller: _emailController,
              size: AppInputSize.medium,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'admin@gmail.com',
                prefixIcon: Icon(
                  Icons.mail_outline_rounded,
                  size: AppSpacing.lg + 2,
                  color: context.colors.onSurfaceSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address';
                }
                if (!AppRegex.email.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            AppSpacing.lg.h,

            // Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppFieldLabel(text: 'Password', isRequired: true),
                // AppButton(
                //   text: 'Forgot password?',
                //   type: ButtonType.text,
                //   size: ButtonSize.small,
                //   fullWidth: false,
                //   onPressed: _onForgotPasswordClick,
                // ),
              ],
            ),
            AppSpacing.xs.h,
            AppTextField.password(
              controller: _passwordController,
              size: AppInputSize.medium,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                hintText: '••••••••••••',
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: AppSpacing.lg + 2,
                  color: context.colors.onSurfaceSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            AppSpacing.lg.h,

            // // Remember me
            // AppRadio<String>(
            //   controller: _rememberMeController,
            //   type: AppRadioType.checkbox,
            //   isRow: true,
            //   optionsList: const [
            //     AppRadioOption(
            //       value: 'remember',
            //       label: 'Keep me signed in on this device',
            //     ),
            //   ],
            // ),
            // AppSpacing.xl.h,

            // Sign In Button
            Consumer(
              builder: (context, ref, child) {
                final isLoading = ref.watch(
                  authControllerProvider.select((state) => state.isLoading),
                );

                return AppButton(
                  text: 'Sign in to Console',
                  onPressed: _handleLogin,
                  isLoading: isLoading,
                );
              },
            ),
            AppSpacing.md.h,

            // Demo Autofill Link (subtle and clean)
            if (kDebugMode)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    _emailController.text = 'admin@gmail.com';
                    _passwordController.text = '123456';

                    AppSnackbar.show(
                      message: 'Demo credentials prefilled (admin@gmail.com)',
                      type: SnackbarType.info,
                    );
                  },
                  icon: Icon(
                    Icons.vpn_key_outlined,
                    size: AppSpacing.md + 2,
                    color: context.colors.onSurfaceSecondary,
                  ),
                  label: Text(
                    'Fill demo credentials',
                    style: context.textTheme.bodySmall
                        ?.medium()
                        .colour(context.colors.onSurfaceSecondary)
                        .size(AppSpacing.md),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: AppSpacing.md + 1,
              color: context.colors.onSurfaceSecondary,
            ),
            AppSpacing.xs.w,
            Text(
              'Secure 256-bit SSL encrypted connection',
              style: context.textTheme.labelSmall
                  ?.colour(context.colors.onSurfaceSecondary)
                  .size(AppSpacing.md - 0.5),
            ),
          ],
        ),
        AppSpacing.xs.h,
        Text(
          '© ${DateTime.now().year} GuardUp. All rights reserved.',
          style: context.textTheme.labelSmall
              ?.colour(context.colors.onSurfaceSecondary.withValues(alpha: 0.8))
              .size(AppSpacing.md - 1),
        ),
      ],
    );
  }
}
