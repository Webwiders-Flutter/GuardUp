import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/features/auth/presentation/screens/admin_approval_screen.dart';

import '/app/routes/app_routes.dart';
import '/app/routes/auth_refresh_listenable.dart';
import '/app/screens/main_navigation.screen.dart';
import '/app/screens/not_found_screen.dart';
import '/core/di/injection_container.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/booking/booking.dart';
import '/features/chat/chat.dart';
import '/features/company/company.dart';
import '/features/customer/customer.dart';
import '/features/guard_detail/guard_detail.dart';
import '/features/legal/legal.dart';
import '/features/notifications/notifications.dart';
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
          if (extra
              is ({
                TransactionModel? transaction,
                UserModel? user,
                String? buttonText,
                VoidCallback? onTap,
              })) {
            return PaymentSuccessScreen(
              transaction: extra.transaction,
              user: extra.user,
              buttonText: extra.buttonText,
              onTap: extra.onTap,
            );
          }
          if (extra is Map<String, dynamic>) {
            return PaymentSuccessScreen(
              transaction: extra['transaction'] as TransactionModel?,
              user: extra['user'] as UserModel?,
              buttonText: extra['buttonText'] as String?,
              onTap: extra['onTap'] as VoidCallback?,
            );
          }
          if (extra is TransactionModel) {
            return PaymentSuccessScreen(transaction: extra);
          }
          return const PaymentSuccessScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.adminApproval,
        builder: (context, state) => const AdminApprovalScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home (Role-based dashboard)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => BlocBuilder<AuthBloc, AuthState>(
                  bloc: sl.isRegistered<AuthBloc>() ? sl<AuthBloc>() : null,
                  builder: (context, authState) {
                    if (authState.sessionRole == UserRole.company) {
                      return const CompanyHomeScreen();
                    } else if (authState.sessionRole == UserRole.guard) {
                      return const BodyGuardHomeScreen();
                    }
                    return const CustomerHomeScreen();
                  },
                ),
              ),
            ],
          ),

          // Branch 1: Bookings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookings,
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),

          // Branch 2: Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ConversationsScreen(),
              ),
            ],
          ),

          // Branch 3: Alerts / Notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.companyHome,
        builder: (context, state) => const CompanyHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.bodyguardHome,
        builder: (context, state) => const BodyGuardHomeScreen(),
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
        path: AppRoutes.companyDetails,
        builder: (context, state) {
          final company = state.extra as CompanyModel?;
          return CompanyDetailsScreen(company: company);
        },
      ),
      GoRoute(
        path: AppRoutes.bodyguardInformation,
        builder: (context, state) {
          final guard = state.extra as BodyGuardModel?;
          return BodyGuardProfileScreen(bodyguard: guard);
        },
      ),
      GoRoute(
        path: AppRoutes.customerBodyguardProfile,
        builder: (context, state) {
          final guard = state.extra as BodyGuardModel?;
          return CustomerBodygaurdProfileScreen(bodyguard: guard);
        },
      ),
      GoRoute(
        path: AppRoutes.myBankDetails,
        builder: (context, state) => const MyBankDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.myWallet,
        builder: (context, state) => const MyWalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.searchBodyguards,
        builder: (context, state) => const SearchBodyguardsScreen(),
      ),
      GoRoute(
        path: AppRoutes.allBodyguards,
        builder: (context, state) => const CompanyBodyguardsScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        builder: (context, state) {
          final conversation = state.extra as ConversationModel?;
          return ChatScreen(conversation: conversation);
        },
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
        path: AppRoutes.customerBooking,
        builder: (context, state) {
          final extra = state.extra;
          CompanyModel? company;
          BodyGuardModel? guard;
          if (extra is CompanyModel) {
            company = extra;
          } else if (extra is BodyGuardModel) {
            guard = extra;
          } else if (extra is ({CompanyModel? company, BodyGuardModel? guard})) {
            company = extra.company;
            guard = extra.guard;
          }
          return BookingScreen(company: company, initialBodyguard: guard);
        },
      ),
      GoRoute(
        path: AppRoutes.contactUs,
        builder: (context, state) => const ContactUsScreen(),
      ),
    ],
  );
}
