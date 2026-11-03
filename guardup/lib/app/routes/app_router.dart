import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/app/routes/auth_refresh_listenable.dart';
import '/app/screens/main_navigation.screen.dart';
import '/app/screens/not_found_screen.dart';
import '/core/di/injection_container.dart';
import '/features/auth/auth.dart';
import '/features/company/company.dart';
import '/features/legal/legal.dart';
import '/features/payments/payments.dart';

final class AppRouter {
  AppRouter._();

  /// Global root navigator key for modals, overlays, and dialogs.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static AuthRefreshListenable? _refreshListenable;

  /// Listenable that notifies [GoRouter] whenever [AuthBloc] state changes.
  static AuthRefreshListenable get refreshListenable =>
      _refreshListenable ??= AuthRefreshListenable(sl<AuthBloc>());

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final authState = sl<AuthBloc>().state;

      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;

      // ------------------------------------------------------------
      // 1. Session is unknown (App bootstrap / Splash)
      // ------------------------------------------------------------
      if (authState.isUnknown) {
        return isSplash ? null : AppRoutes.splash;
      }

      // ------------------------------------------------------------
      // 2. Once bootstrap is complete, route away from splash
      // ------------------------------------------------------------
      if (isSplash) {
        return authState.isAuthenticated
            ? AppRoutes.home
            : AppRoutes.login;
      }

      // ------------------------------------------------------------
      // 3. Unauthenticated session
      // ------------------------------------------------------------
      if (authState.isUnauthenticated) {
        final unauthenticatedRoutes = {
          AppRoutes.selectRole,
          AppRoutes.onboarding,
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.register,
          AppRoutes.forgotPassword,
          AppRoutes.resetPassword,
          AppRoutes.verifyOtp,
          AppRoutes.emailVerification,
          AppRoutes.uploadDocuments,
          AppRoutes.registrationFee,
          AppRoutes.paymentSuccess,
          AppRoutes.adminApproval,
          AppRoutes.home,
          AppRoutes.editProfile,
          AppRoutes.changePassword,
          AppRoutes.membershipPlans,
          AppRoutes.privacyPolicy,
          AppRoutes.termsAndConditions,
          AppRoutes.contactUs,
        };

        // Allowed to access authentication & onboarding routes.
        if (unauthenticatedRoutes.contains(location)) {
          return null;
        }

        // All other routes require authentication.
        return isLogin ? null : AppRoutes.login;
      }

      // ------------------------------------------------------------
      // 4. Authenticated session
      // ------------------------------------------------------------
      if (authState.isAuthenticated) {
        final authenticatedRedirectRoutes = {
          AppRoutes.splash,
          AppRoutes.selectRole,
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.register,
          AppRoutes.onboarding,
          AppRoutes.blocked,
        };

        // Fully authenticated users should redirect away from entry pages.
        if (authenticatedRedirectRoutes.contains(location)) {
          return AppRoutes.home;
        }
      }

      // Current route is valid.
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectRole,
        builder: (context, state) => const SelectRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyDetails,
        builder: (context, state) => const CompanyDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.uploadDocuments,
        builder: (context, state) => const UploadDocumentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.registrationFee,
        builder: (context, state) => const RegistrationFeeScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (context, state) {
          final extra = state.extra;
          return PaymentSuccessScreen(
            args: extra is PaymentSuccessArgs ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminApproval,
        builder: (context, state) => const AdminApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.membershipPlans,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MembershipPlanArgs) {
            return MembershipPlansScreen(
              mode: extra.mode ?? MembershipPlanMode.profile,
              bookingAmount: extra.bookingAmount,
              operativeName: extra.operativeName,
              activePlanId: extra.activePlanId ?? 'gold_sentinel',
            );
          }
          return const MembershipPlansScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) =>
            const LegalContentScreen(type: ContentType.privacyPolicy),
      ),
      GoRoute(
        path: AppRoutes.termsAndConditions,
        builder: (context, state) =>
            const LegalContentScreen(type: ContentType.terms),
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsScreen(),
      ),
    ],
  );
}
