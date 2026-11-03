import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/auth/presentation/screens/admin_approval_screen.dart';
import 'package:guardup/features/body_guard/presentation/screens/body_guard_complete_profile_screen.dart';
import 'package:guardup/features/body_guard/presentation/screens/body_guard_upload_documents_screen.dart';

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
        return authState.isAuthenticated ? AppRoutes.home : AppRoutes.login;
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
        path: AppRoutes.companyProfile,
        builder: (context, state) => const CompanyCompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.bodyguardProfile,
        builder: (context, state) => const BodyGuardCompleteProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.bodyguardUploadDocuments,
        builder: (context, state) => const BodyGuardUploadDocumentsScreen(),
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
        path: AppRoutes.companyEditProfile,
        builder: (context, state) => const CompanyEditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyInformation,
        builder: (context, state) => const CompanyInformationScreen(),
      ),
      GoRoute(
        path: AppRoutes.myBankDetails,
        builder: (context, state) => const MyBankDetailsScreen(),
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
