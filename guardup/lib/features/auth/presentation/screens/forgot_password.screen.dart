import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/enum/otp_type.enum.dart';
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
import '/gen/assets.gen.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';
import '/features/auth/presentation/screens/email_verification.screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const route = '/forgotPassword';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _emailController.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoadingNotifier.value) return;

    final email = _emailController.text.trim().toLowerCase();
    _isLoadingNotifier.value = true;

    // Check if email exists in database before proceeding
    if (sl.isRegistered<UserRepository>()) {
      final checkResult =
          await sl<UserRepository>().checkEmailExists(email);
      if (!checkResult.exists) {
        _isLoadingNotifier.value = false;
        if (mounted) {
          AppSnackbar.error(
            checkResult.errorMessage ?? context.l10n.emailNotFound,
          );
        }
        return;
      }
    }

    sl<AuthBloc>().add(AuthSendPasswordResetRequested(email: email));
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!_isLoadingNotifier.value) return;

    if (state.hasError) {
      _isLoadingNotifier.value = false;
      AppSnackbar.error(
        state.errorMessage ??
            'Failed to send password reset code. Please try again.',
      );
    } else if (state.operationState.isSuccess) {
      _isLoadingNotifier.value = false;
      final email = _emailController.text.trim().toLowerCase();
      AppSnackbar.info('A verification code has been sent to $email');
      context.push(
        '${EmailVerificationScreen.route}?email=${Uri.encodeComponent(email)}&type=RECOVERY',
        extra: <String, dynamic>{
          'email': email,
          'otpType': OtpType.recovery,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      bloc: sl<AuthBloc>(),
      listener: _onAuthStateChanged,
      child: Scaffold(
        appBar: AppAppBar.transparent(
          showBackIcon: true,
          onBackTap: () => context.pop(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSpacing.lg.h,

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
                            style: context.textTheme.headlineLarge?.bold(),
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
                          ValueListenableBuilder<bool>(
                            valueListenable: _isLoadingNotifier,
                            builder: (context, isLoading, _) {
                              return AppButton(
                                text: context.l10n.submit,
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _handleSubmit,
                              );
                            },
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
      ),
    );
  }
}
