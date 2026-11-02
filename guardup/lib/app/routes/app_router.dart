import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/app/routes/auth_refresh_listenable.dart';
import '/app/screens/not_found_screen.dart';
import '/core/di/injection_container.dart';
import '/features/auth/auth.dart';

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
      // 1. Auth initialization / loading state
      // ------------------------------------------------------------
      if (authState.isLoading || authState.isInitial) {
        return isSplash ? null : AppRoutes.splash;
      }

      // ------------------------------------------------------------
      // 2. Unauthenticated user
      // ------------------------------------------------------------
      if (authState.isUnauthenticated) {
        final unauthenticatedRoutes = {
          AppRoutes.onboarding,
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.register,
          AppRoutes.forgotPassword,
          AppRoutes.resetPassword,
          AppRoutes.verifyOtp,
        };

        // Allowed to access authentication & onboarding routes.
        if (unauthenticatedRoutes.contains(location)) {
          return null;
        }

        // All other routes require authentication.
        return isLogin ? null : AppRoutes.login;
      }

      // ------------------------------------------------------------
      // 3. Authenticated user
      // ------------------------------------------------------------
      if (authState.isAuthenticated) {
        final authenticatedRedirectRoutes = {
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.signup,
          AppRoutes.register,
          AppRoutes.onboarding,
          AppRoutes.blocked,
          AppRoutes.adminApproval,
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
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Login Screen'),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Home Screen'),
          ),
        ),
      ),
    ],
  );
}
