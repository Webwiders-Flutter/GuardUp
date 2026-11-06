import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // if (!(_formKey.currentState?.validate() ?? false)) return;
    context.go(AppRoutes.home);
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
                              context.push(AppRoutes.forgotPassword);
                            },
                          ),
                        ),
                        AppSpacing.xl.h,

                        // 6. Login Primary Button
                        AppButton(
                          text: context.l10n.login,

                          onPressed: _handleLogin,
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
                                  context.push(AppRoutes.selectRole);
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
