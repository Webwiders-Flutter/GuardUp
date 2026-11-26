import 'package:flutter_test/flutter_test.dart';

import 'package:guardup/app/routes/redirect.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/body_guard/body_guard.dart';
import 'package:guardup/features/company/company.dart';
import 'package:guardup/features/customer/customer.dart';
import 'package:guardup/features/legal/legal.dart';
import 'package:guardup/features/payments/payments.dart';

void main() {
  UserModel userWith({
    UserRole role = UserRole.customer,
    UserStatus status = UserStatus.active,
    String? rejectionReason,
  }) => UserModel(
    id: 'user-1',
    name: 'Test User',
    role: role,
    status: status,
    rejectionReason: rejectionReason,
  );

  group('resolveRedirect', () {
    test('unknown session keeps splash or redirects to splash', () {
      const state = AuthState.unknown();
      expect(
        resolveRedirect(authState: state, location: SplashScreen.route),
        isNull,
      );
      expect(
        resolveRedirect(authState: state, location: CustomerHomeScreen.route),
        SplashScreen.route,
      );
    });

    test('splash and /download route by auth and onboarding state', () {
      expect(
        resolveRedirect(
          authState: const AuthState.unauthenticated(),
          location: SplashScreen.route,
        ),
        LoginScreen.route,
      );
      expect(
        resolveRedirect(
          authState: AuthState.authenticated(
            userWith(role: UserRole.guard, status: UserStatus.blocked),
          ),
          location: '/download',
        ),
        AccountStatusScreen.blockedRoute,
      );
      expect(
        resolveRedirect(
          authState: AuthState.authenticated(
            userWith(role: UserRole.guard, status: UserStatus.pendingApproval),
          ),
          location: SplashScreen.route,
        ),
        AdminApprovalScreen.route,
      );
      expect(
        resolveRedirect(
          authState: AuthState.authenticated(
            userWith(role: UserRole.guard, status: UserStatus.incomplete),
          ),
          location: SplashScreen.route,
        ),
        BodyGuardCompleteProfileScreen.route,
      );
      expect(
        resolveRedirect(
          authState: AuthState.authenticated(
            userWith(role: UserRole.company, status: UserStatus.incomplete),
          ),
          location: SplashScreen.route,
        ),
        CompanyCompleteProfileScreen.route,
      );
      expect(
        resolveRedirect(
          authState: AuthState.authenticated(
            userWith(role: UserRole.customer, status: UserStatus.active),
          ),
          location: SplashScreen.route,
        ),
        CustomerHomeScreen.route,
      );
    });

    test('unauthenticated allows public routes and guards private routes', () {
      const state = AuthState.unauthenticated();
      for (final route in [
        LoginScreen.route,
        SignUpScreen.route,
        SelectRoleScreen.route,
        ForgotPasswordScreen.route,
        EmailVerificationScreen.route,
        ResetPasswordScreen.route,
        ContactUsScreen.route,
        LegalContentScreen.privacyPolicyRoute,
        LegalContentScreen.termsRoute,
        AccountStatusScreen.deletedRoute,
      ]) {
        expect(resolveRedirect(authState: state, location: route), isNull);
      }

      expect(
        resolveRedirect(authState: state, location: CustomerHomeScreen.route),
        LoginScreen.route,
      );
    });

    test('blocked user stays on blocked/legal routes and redirects others', () {
      final state = AuthState.authenticated(
        userWith(role: UserRole.guard, status: UserStatus.blocked),
      );
      expect(
        resolveRedirect(
          authState: state,
          location: AccountStatusScreen.blockedRoute,
        ),
        isNull,
      );
      expect(
        resolveRedirect(authState: state, location: ContactUsScreen.route),
        isNull,
      );
      expect(
        resolveRedirect(authState: state, location: CustomerHomeScreen.route),
        AccountStatusScreen.blockedRoute,
      );
    });

    test('unblocked user leaves blocked screen to active destination', () {
      final state = AuthState.authenticated(
        userWith(role: UserRole.guard, status: UserStatus.active),
      );
      expect(
        resolveRedirect(
          authState: state,
          location: AccountStatusScreen.blockedRoute,
        ),
        CustomerHomeScreen.route,
      );
    });

    test('deleted user stays on deleted/legal routes and redirects others', () {
      final state = AuthState.authenticated(
        userWith(role: UserRole.guard, status: UserStatus.deleted),
      );
      expect(
        resolveRedirect(
          authState: state,
          location: AccountStatusScreen.deletedRoute,
        ),
        isNull,
      );
      expect(
        resolveRedirect(authState: state, location: CustomerHomeScreen.route),
        AccountStatusScreen.deletedRoute,
      );
    });

    test('pending approval restricts user to approval/payment/legal routes', () {
      final state = AuthState.authenticated(
        userWith(role: UserRole.guard, status: UserStatus.pendingApproval),
      );
      expect(
        resolveRedirect(authState: state, location: AdminApprovalScreen.route),
        isNull,
      );
      expect(
        resolveRedirect(authState: state, location: PaymentSuccessScreen.route),
        isNull,
      );
      expect(
        resolveRedirect(
          authState: state,
          location: BodyGuardCompleteProfileScreen.route,
        ),
        AdminApprovalScreen.route,
      );
    });

    test('rejected user can visit profile and rejected document upload routes', () {
      final state = AuthState.authenticated(
        userWith(
          role: UserRole.guard,
          status: UserStatus.rejected,
          rejectionReason: 'Bad bio',
        ),
        userDocuments: const [
          UserDocumentModel(
            id: 'd1',
            documentTypeId: 'dt1',
            fileUrl: 'https://example.com/doc.pdf',
            status: DocumentStatus.rejected,
          ),
        ],
      );
      expect(
        resolveRedirect(
          authState: state,
          location: BodyGuardCompleteProfileScreen.route,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          authState: state,
          location: BodyGuardUploadDocumentsScreen.route,
        ),
        isNull,
      );
      expect(
        resolveRedirect(authState: state, location: CustomerHomeScreen.route),
        AdminApprovalScreen.route,
      );
    });

    test('incomplete onboarding forces role profile/document/payment routes', () {
      final guardIncomplete = AuthState.authenticated(
        userWith(role: UserRole.guard, status: UserStatus.incomplete),
      );
      expect(
        resolveRedirect(
          authState: guardIncomplete,
          location: BodyGuardCompleteProfileScreen.route,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          authState: guardIncomplete,
          location: RegistrationFeeScreen.route,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          authState: guardIncomplete,
          location: CustomerHomeScreen.route,
        ),
        BodyGuardCompleteProfileScreen.route,
      );

      final companyIncomplete = AuthState.authenticated(
        userWith(role: UserRole.company, status: UserStatus.incomplete),
      );
      expect(
        resolveRedirect(
          authState: companyIncomplete,
          location: UploadDocumentsScreen.route,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          authState: companyIncomplete,
          location: CustomerHomeScreen.route,
        ),
        CompanyCompleteProfileScreen.route,
      );
    });

    test('approved company can open bodyguard onboarding/approval for managed guards, while approved customer/guard cannot', () {
      final approvedCompany = AuthState.authenticated(
        userWith(role: UserRole.company, status: UserStatus.active),
      );
      expect(
        resolveRedirect(
          authState: approvedCompany,
          location: BodyGuardCompleteProfileScreen.route,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          authState: approvedCompany,
          location: AdminApprovalScreen.route,
        ),
        isNull,
      );
      expect(
        resolveRedirect(
          authState: approvedCompany,
          location: CompanyCompleteProfileScreen.route,
        ),
        CustomerHomeScreen.route,
      );

      final approvedCustomer = AuthState.authenticated(
        userWith(role: UserRole.customer, status: UserStatus.active),
      );
      expect(
        resolveRedirect(
          authState: approvedCustomer,
          location: LoginScreen.route,
        ),
        CustomerHomeScreen.route,
      );
      expect(
        resolveRedirect(
          authState: approvedCustomer,
          location: BodyGuardCompleteProfileScreen.route,
        ),
        CustomerHomeScreen.route,
      );
    });
  });
}
