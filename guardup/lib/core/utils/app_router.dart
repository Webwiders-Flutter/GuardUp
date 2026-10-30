import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/features/auth/presentation/screens/admin_approved_screen.dart';
import 'package:guardup/features/auth/presentation/screens/change_email_screen.dart';
import 'package:guardup/features/auth/presentation/screens/change_password_screen.dart';
import 'package:guardup/features/auth/presentation/screens/change_phone_screen.dart';
import 'package:guardup/features/auth/presentation/screens/email_confirmation_screen.dart';
import 'package:guardup/features/auth/presentation/screens/email_verified_screen.dart';
import 'package:guardup/features/auth/presentation/screens/login_screen.dart';
import 'package:guardup/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:guardup/features/auth/presentation/screens/privacy_policy_screen.dart';
import 'package:guardup/features/auth/presentation/screens/signup_screen.dart';
import 'package:guardup/features/auth/presentation/screens/splash_screen.dart';
import 'package:guardup/features/auth/presentation/screens/terms_condtion_screen.dart';
import 'package:guardup/features/auth/presentation/screens/verification_otp_screen.dart';
import 'package:guardup/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:guardup/features/help_centre/presentation/screens/create_ticket_screen.dart';
import 'package:guardup/features/help_centre/presentation/screens/my_tickets_screen.dart';
import 'package:guardup/features/help_centre/presentation/screens/support_center_screen.dart';
import 'package:guardup/features/help_centre/presentation/screens/ticket_detail_screen.dart';
import 'package:guardup/features/profile/presentation/screens/blocked_users_screen.dart';
import 'package:guardup/features/profile/presentation/screens/edit_profile_screen.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/screens/create_new_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/help_centre/domain/entities/ticket_entity.dart';
import '../widgets/common/custom_image_viewer.dart';
import 'app_logs.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static const String root = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String emailConfirmation = '/email-confirmation';
  static const String loginCallback = '/auth-callback';
  static const String enterOtp = '/enter-otp';
  static const String adminApproved = '/admin_approved';
  static const String createNewPassword = '/create-new-password';
  static const String editProfile = '/edit-profile';
  // static const String home = '/home';
  static const String dashboardScreen = '/dashboardScreen';

  // static const String profile = '/profile';
  // static const String settings = '/settings';
  static const String forgotPasswordScreen = '/forgot-password';
  static const String verifyEmailScreen = '/verify-email';
  static const String changePasswordScreen = '/change-password';
  static const String changeEmailScreen = '/change-email';
  static const String changePhoneScreen = '/change-phone';
  static const String privacyPolicyScreen = '/privacy-policy';
  static const String termsAndConditionScreen = '/terms-condition';
  static const String onboarding = '/onboarding-screen';
  static const String documentViewer = '/document-viewer';
  static const String supportCenter = '/support-center';
  static const String createTicket = '/create-ticket';
  static const String myTickets = '/my-tickets';
  static const String ticketDetail = '/ticket-detail';
  static const String chatScreen = '/chat-screen';
  static const String myChats = '/my-chats';
  static const String blockedUsers = '/blocked-users';
  static const String selectCountry = '/select-country';
  static const String uploadDocument = '/upload-document';
  static const String imageViewer = '/image-viewer';

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: root,
    refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = sl<AuthBloc>().state;
      // final authRoutes = [
      //   root,
      //   onboarding,
      //   login,
      //   signup,
      //   emailConfirmation,
      //   loginCallback,
      //   enterOtp,
      //   changePasswordScreen,
      //   adminApproved,
      //   forgotPasswordScreen,
      //   verifyEmailScreen,
      //   privacyPolicyScreen,
      //   termsAndConditionScreen,
      //   createNewPassword,
      // ];
      final loginOnlyRoutes = [
        login,
        signup,
        emailConfirmation,
        root,
        enterOtp,
        adminApproved,
        forgotPasswordScreen,
        verifyEmailScreen,
      ];
      final locationPath = state.uri.path.isEmpty ? root : state.uri.path;
      final isGoingToLogin = loginOnlyRoutes.contains(locationPath);

      if (state.uri.path.isEmpty) {
        return root;
      }

      if (authState is AuthInitialState) {
        AppLogs.debugPrint('App Initialized via URI: ${state.uri}');
        // Return null instead of root to preserve deep links on app launch.
        // GoRouter will temporarily load the requested route (or Splash if root)
        // until AuthBloc resolves.
        return null;
      }

      final fragmentParams = Uri.splitQueryString(state.uri.fragment);
      final hasError =
          state.uri.queryParameters.containsKey('error') ||
          state.uri.queryParameters.containsKey('error_code') ||
          fragmentParams.containsKey('error') ||
          fragmentParams.containsKey('error_code');

      final isRecovery =
          !hasError &&
          (state.uri.queryParameters['type'] == 'recovery' ||
              fragmentParams['type'] == 'recovery' ||
              locationPath == createNewPassword ||
              authState is AuthPasswordRecoveryState);

      if (isRecovery) {
        if (locationPath != createNewPassword) return createNewPassword;
        return null;
      }

      if (authState is UnAuthenticatedState) {
        if (locationPath == root) return dashboardScreen;
      }

      if (authState is AuthenticatedState) {
        if (isGoingToLogin) {
          // Let the screens handle the redirect to preferences or dashboard themselves
          // Because async logic inside GoRouter redirect causes UI freezing!
          return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: root, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: onboarding,
        name: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: login,
        name: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        name: signup,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: emailConfirmation,
        name: emailConfirmation,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return EmailConfirmationScreen(email: email);
        },
      ),
      GoRoute(
        path: loginCallback,
        name: loginCallback,
        builder: (context, state) {
          final fragment = state.uri.fragment;
          final fragmentParams = Uri.splitQueryString(fragment);

          final type =
              state.uri.queryParameters['type'] ?? fragmentParams['type'];
          final error =
              state.uri.queryParameters['error'] ?? fragmentParams['error'];
          final errorCode =
              state.uri.queryParameters['error_code'] ??
              fragmentParams['error_code'];
          final errorDescription =
              state.uri.queryParameters['error_description'] ??
              fragmentParams['error_description'];

          if (type == 'recovery' && error == null && errorCode == null) {
            return const CreateNewPasswordScreen();
          }

          return EmailVerifiedScreen(
            type: type,
            error: error,
            errorCode: errorCode,
            errorDescription: errorDescription?.replaceAll('+', ' '),
          );
        },
      ),
      GoRoute(
        path: enterOtp,
        name: enterOtp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerificationOtpScreen(
            routeName: extra?['routeName'] as String?,
            email: extra?['email'] as String?,
            phoneCode: extra?['phoneCode'] as String?,
            countryCode: extra?['countryCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: adminApproved,
        name: adminApproved,
        builder: (context, state) => const AdminApprovedScreen(),
      ),
      GoRoute(
        path: dashboardScreen,
        name: dashboardScreen,
        builder: (context, state) => const DashboardScreen(),
      ),

      GoRoute(
        path: editProfile,
        name: editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),

      GoRoute(
        path: forgotPasswordScreen,
        name: forgotPasswordScreen,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: createNewPassword,
        name: createNewPassword,
        builder: (context, state) => const CreateNewPasswordScreen(),
      ),

      GoRoute(
        path: changePasswordScreen,
        name: changePasswordScreen,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: changeEmailScreen,
        name: changeEmailScreen,
        builder: (context, state) => const ChangeEmailScreen(),
      ),
      GoRoute(
        path: changePhoneScreen,
        name: changePhoneScreen,
        builder: (context, state) => const ChangePhoneScreen(),
      ),
      GoRoute(
        path: privacyPolicyScreen,
        name: privacyPolicyScreen,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      GoRoute(
        path: termsAndConditionScreen,
        name: termsAndConditionScreen,
        builder: (context, state) => const TermsAndConditionScreen(),
      ),

      GoRoute(
        path: supportCenter,
        name: supportCenter,
        builder: (context, state) => const SupportCenterScreen(),
      ),

      GoRoute(
        path: createTicket,
        name: createTicket,
        builder: (context, state) => const CreateTicketScreen(),
      ),

      GoRoute(
        path: myTickets,
        name: myTickets,
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: ticketDetail,
        name: ticketDetail,
        builder: (context, state) =>
            TicketDetailScreen(ticket: state.extra as TicketEntity),
      ),

      GoRoute(
        path: blockedUsers,
        name: blockedUsers,
        builder: (context, state) => const BlockedUsersScreen(),
      ),

      GoRoute(
        path: imageViewer,
        name: imageViewer,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CustomImageViewer(
            imageUrl: args['imageUrl'] as String,
            heroTag: args['heroTag'] as String,
          );
        },
      ),
    ],
  );
}
