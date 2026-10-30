import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

class EmailVerifiedScreen extends StatelessWidget {
  final String? type;
  final String? error;
  final String? errorCode;
  final String? errorDescription;

  const EmailVerifiedScreen({
    super.key,
    this.type,
    this.error,
    this.errorCode,
    this.errorDescription,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated =
        context.read<AuthBloc>().state is AuthenticatedState ||
        (sl.isRegistered<AuthRepository>() &&
            sl<AuthRepository>().currentUser != null);

    final String lowerError = (errorDescription ?? error ?? '').toLowerCase();
    final bool isOtpExpired =
        errorCode == 'otp_expired' || lowerError.contains('otp_expired');
    final bool isLinkExpiredOrUsed =
        lowerError.contains('token has expired') ||
        lowerError.contains('expired or is invalid') ||
        lowerError.contains('invalid or has expired');

    final bool hasError =
        error != null || errorCode != null || errorDescription != null;

    // For password recovery error or expired recovery link
    final bool isRecoveryExpired = type == 'recovery' && hasError;

    // For explicit signup flow, mail scanner prefetching consumes the token.
    // In that case, Supabase returns otp_expired, but the user is already verified.
    final bool isSignupScannerUsed =
        type == 'signup' && hasError && (isOtpExpired || isLinkExpiredOrUsed);

    final bool isSuccess =
        !isRecoveryExpired &&
        (isSignupScannerUsed ||
            (!hasError && (isAuthenticated || type != 'recovery')));

    final bool isGenericError =
        hasError && !isSignupScannerUsed && !isRecoveryExpired;

    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedState && isSuccess) {
            context.read<AuthBloc>().add(const AuthRefreshEvent());
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                context.go(AppRouter.dashboardScreen);
              }
            });
          }
        },
        child: Builder(
          builder: (context) {
            if (isAuthenticated && isSuccess) {
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) {
                  context.go(AppRouter.dashboardScreen);
                }
              });
            }

            final IconData displayIcon;
            final Color iconColor;
            final String displayTitle;
            final String displayMessage;

            if (isRecoveryExpired) {
              displayIcon = Icons.lock_reset_rounded;
              iconColor = Colors.redAccent;
              displayTitle = context.l10n.resetPasswordLinkExpired;
              displayMessage = context.l10n.resetPasswordLinkExpiredDesc;
            } else if (isGenericError) {
              displayIcon = Icons.error_outline_rounded;
              iconColor = Colors.redAccent;
              displayTitle = context.l10n.verificationFailed;
              displayMessage =
                  errorDescription ?? context.l10n.theLinkIsInvalidOrExpired;
            } else if (isAuthenticated) {
              displayIcon = Icons.check_circle_outline;
              iconColor = AppColors.secondary;
              displayTitle = context.l10n.accountAlreadyVerified;
              displayMessage = context.l10n.youAreAlreadyLoggedIn;
            } else {
              displayIcon = Icons.check_circle_outline;
              iconColor = AppColors.secondary;
              displayTitle = context.l10n.emailVerified;
              displayMessage =
                  context.l10n.yourEmailHasBeenSuccessfullyVerified;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(displayIcon, size: 100, color: iconColor),
                  const SizedBox(height: 32),
                  AppText(
                    displayTitle,
                    type: AppTextType.bodyMedium,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    displayMessage,
                    type: AppTextType.bodySmall,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.headingTextFieldColor,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  if (isRecoveryExpired) ...[
                    AppButton(
                      height: 50,
                      buttonColor: AppColors.secondary,
                      text: context.l10n.requestNewLink,
                      textColor: AppColors.blackColor,
                      onPressed: () {
                        context.go(AppRouter.forgotPasswordScreen);
                      },
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      height: 50,
                      buttonColor: Colors.transparent,
                      borderColor: AppColors.secondary,
                      borderWidth: 1.5,
                      text: isAuthenticated
                          ? context.l10n.goToDashboard
                          : context.l10n.goToLogin,
                      textColor: AppColors.secondary,
                      onPressed: () {
                        context.go(
                          isAuthenticated
                              ? AppRouter.dashboardScreen
                              : AppRouter.login,
                        );
                      },
                    ),
                  ] else if (isGenericError) ...[
                    AppButton(
                      height: 50,
                      buttonColor: AppColors.secondary,
                      text: isAuthenticated
                          ? context.l10n.goToDashboard
                          : context.l10n.goToLogin,
                      textColor: AppColors.blackColor,
                      onPressed: () {
                        context.go(
                          isAuthenticated
                              ? AppRouter.dashboardScreen
                              : AppRouter.login,
                        );
                      },
                    ),
                    if (!isAuthenticated) ...[
                      const SizedBox(height: 12),
                      AppButton(
                        height: 50,
                        buttonColor: Colors.transparent,
                        borderColor: AppColors.secondary,
                        borderWidth: 1.5,
                        text: context.l10n.signup,
                        textColor: AppColors.secondary,
                        onPressed: () {
                          context.go(AppRouter.signup);
                        },
                      ),
                    ],
                  ] else if (isAuthenticated)
                    AppButton(
                      height: 50,
                      buttonColor: AppColors.secondary,
                      text: context.l10n.goToDashboard,
                      textColor: AppColors.blackColor,
                      onPressed: () {
                        context.go(AppRouter.dashboardScreen);
                      },
                    )
                  else
                    AppButton(
                      height: 50,
                      buttonColor: AppColors.secondary,
                      text: context.l10n.goToLogin,
                      textColor: AppColors.blackColor,
                      onPressed: () {
                        context.go(AppRouter.login);
                      },
                    ),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
