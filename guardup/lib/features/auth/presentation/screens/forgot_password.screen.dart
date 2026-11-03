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
import '/shared/widgets/sections/app_image.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // if (!(_formKey.currentState?.validate() ?? false)) return;
    context.push(AppRoutes.verifyOtp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
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

                        // 1. GuardUp Logo (Centered)
                        Center(
                          child: AppImage.asset(
                            assetPath: Assets.images.appLogo.path,
                            height: 32.wPercent(context),
                            fit: BoxFit.contain,
                          ),
                        ),
                        AppSpacing.massive.h,

                        // 2. Heading
                        Text(
                          context.l10n.forgotPasswordTitle,
                          style: context.textTheme.headlineLarge?.bold().colour(
                            context.colors.onSurface,
                          ),
                        ),
                        AppSpacing.xs.h,

                        // 3. Subtitle
                        Text(
                          context.l10n.forgotPasswordSubtitle,
                          style: context.textTheme.bodyMedium?.colour(
                            context.colors.onSurfaceVariant,
                          ),
                        ),
                        AppSpacing.xxl.h,

                        // 4. Email Field (Uses default theme styling)
                        AppTextField.email(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: context.l10n.emailAddress,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) =>
                              Validators.email(context, value),
                          onFieldSubmitted: (_) => _handleSubmit(),
                        ),

                        const Spacer(),
                        AppSpacing.lg.h,

                        // 5. Submit Button pinned to bottom
                        AppButton(
                          text: context.l10n.submit,
                          size: ButtonSize.large,
                          onPressed: _handleSubmit,
                        ),
                        AppSpacing.xl.h,
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
