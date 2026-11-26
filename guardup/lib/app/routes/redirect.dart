import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/company/company.dart';
import '/features/customer/customer.dart';
import '/features/legal/legal.dart';
import '/features/payments/payments.dart';

/// Pure route redirect resolution based on [authState] and current [location].
///
/// Extracted from `AppRouter` so every branch can be unit-tested cleanly.
String? resolveRedirect({
  required AuthState authState,
  required String location,
}) {
  final isSplash = location == SplashScreen.route;

  // ------------------------------------------------------------
  // 1. Session is unknown (App bootstrap / Splash)
  // ------------------------------------------------------------
  if (authState.isUnknown) {
    return isSplash ? null : SplashScreen.route;
  }

  // ------------------------------------------------------------
  // 2. Once bootstrap is complete, route away from splash / deep link
  // ------------------------------------------------------------
  if (isSplash || location == '/download') {
    if (!authState.isAuthenticated) {
      return LoginScreen.route;
    }
    if (authState.isBlocked) {
      return AccountStatusScreen.blockedRoute;
    }
    if (authState.isPendingApproval || authState.isRejected) {
      return AdminApprovalScreen.route;
    }
    if (authState.requiresOnboarding) {
      if (authState.isGuard) return BodyGuardCompleteProfileScreen.route;
      if (authState.isCompany) return CompanyCompleteProfileScreen.route;
    }
    return CustomerHomeScreen.route;
  }

  // ------------------------------------------------------------
  // 3. User is Unauthenticated: block access to protected routes
  // ------------------------------------------------------------
  if (!authState.isAuthenticated) {
    final isPublicRoute =
        isSplash ||
        location == LoginScreen.route ||
        location == SignUpScreen.route ||
        location == SelectRoleScreen.route ||
        location == ForgotPasswordScreen.route ||
        location == EmailVerificationScreen.route ||
        location == ResetPasswordScreen.route ||
        location == ContactUsScreen.route ||
        location == LegalContentScreen.privacyPolicyRoute ||
        location == LegalContentScreen.termsRoute ||
        location == AccountStatusScreen.deletedRoute;

    return isPublicRoute ? null : LoginScreen.route;
  }

  // ------------------------------------------------------------
  // 4. User is Authenticated: enforce onboarding step clearance & realtime admin status
  // ------------------------------------------------------------
  if (authState.isAuthenticated) {
    // Allow user to stay on Reset Password or Email Verification screen while completing recovery
    if (location == ResetPasswordScreen.route ||
        location == EmailVerificationScreen.route) {
      return null;
    }

    final isAuthFlow =
        location == LoginScreen.route ||
        location == SignUpScreen.route ||
        location == SelectRoleScreen.route;

    // A. Account is blocked by Admin
    if (authState.isBlocked) {
      final isAllowedBlocked =
          location == AccountStatusScreen.blockedRoute ||
          location == ContactUsScreen.route ||
          location == LegalContentScreen.privacyPolicyRoute ||
          location == LegalContentScreen.termsRoute;

      return isAllowedBlocked ? null : AccountStatusScreen.blockedRoute;
    }

    // Redirect away from blocked screen when unblocked
    if (location == AccountStatusScreen.blockedRoute) {
      if (authState.isPendingApproval || authState.isRejected) {
        return AdminApprovalScreen.route;
      }
      if (authState.requiresOnboarding) {
        if (authState.isGuard) return BodyGuardCompleteProfileScreen.route;
        if (authState.isCompany) return CompanyCompleteProfileScreen.route;
      }
      return CustomerHomeScreen.route;
    }

    // B. Account is deleted by Admin or User
    if (authState.isDeleted) {
      final isAllowedDeleted =
          location == AccountStatusScreen.deletedRoute ||
          location == ContactUsScreen.route ||
          location == LegalContentScreen.privacyPolicyRoute ||
          location == LegalContentScreen.termsRoute;

      return isAllowedDeleted ? null : AccountStatusScreen.deletedRoute;
    }

    if (location == AccountStatusScreen.deletedRoute) {
      return LoginScreen.route;
    }

    // C. Application submitted (waiting for Admin review) or Rejected by Admin
    if (authState.isPendingApproval || authState.isRejected) {
      final isAllowedPending =
          location == AdminApprovalScreen.route ||
          location == PaymentSuccessScreen.route ||
          location == ContactUsScreen.route ||
          location == LegalContentScreen.privacyPolicyRoute ||
          location == LegalContentScreen.termsRoute ||
          (authState.isRejected &&
              ((authState.hasRejectedDocuments &&
                      (location == BodyGuardUploadDocumentsScreen.route ||
                          location == UploadDocumentsScreen.route)) ||
                  location == BodyGuardCompleteProfileScreen.route ||
                  location == CompanyCompleteProfileScreen.route));

      if (!isAllowedPending) {
        return AdminApprovalScreen.route;
      }
      return null;
    }

    // D. Onboarding step is incomplete: redirect directly to left step
    if (authState.requiresOnboarding) {
      final isOnboardingPayment =
          location == RegistrationFeeScreen.route ||
          location == PaymentSuccessScreen.route;

      if (isOnboardingPayment) {
        return null;
      }

      if (authState.isGuard) {
        final isGuardOnboarding =
            location == BodyGuardCompleteProfileScreen.route ||
            location == BodyGuardUploadDocumentsScreen.route;
        return isGuardOnboarding
            ? null
            : BodyGuardCompleteProfileScreen.route;
      }
      if (authState.isCompany) {
        final isCompanyOnboarding =
            location == CompanyCompleteProfileScreen.route ||
            location == UploadDocumentsScreen.route;
        return isCompanyOnboarding ? null : CompanyCompleteProfileScreen.route;
      }
    }

    // E. Fully approved user trying to access login/signup/approval or other role onboarding screens.
    // Note: BodyGuardCompleteProfileScreen, BodyGuardUploadDocumentsScreen, and AdminApprovalScreen
    // are NOT blocked for companies because companies manage bodyguards and review their submissions.
    if (authState.isApproved &&
        (isAuthFlow ||
            (!authState.isCompany &&
                (location == AdminApprovalScreen.route ||
                    location == BodyGuardCompleteProfileScreen.route ||
                    location == BodyGuardUploadDocumentsScreen.route)) ||
            location == CompanyCompleteProfileScreen.route)) {
      return CustomerHomeScreen.route;
    }
  }

  // Current route is valid.
  return null;
}
