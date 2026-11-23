import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/auth_refresh_listenable.dart';
import '/app/screens/admin_shell.dart';
import '/app/screens/not_found_screen.dart';
import '/core/enums/language.enum.dart';
import '/features/auth/di/auth.providers.dart';
import '/features/auth/presentation/screens/login.screen.dart';
import '/features/auth/presentation/screens/profile.screen.dart';
import '/features/dashboard/presentation/screens/dashboard.screen.dart';
import '/features/document-type/presentation/screens/document_type_management.screen.dart';
import '/features/download/presentation/screens/public_download.screen.dart';
import '/features/help-support/presentation/screens/help_support_management.screen.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/legal/data/models/faq.model.dart';
import '/features/legal/presentation/screens/content_management.screen.dart';
import '/features/legal/presentation/screens/faq.form.dart';
import '/features/legal/presentation/screens/faq_management.screen.dart';
import '/features/legal/presentation/screens/public_legal.screen.dart';
import '/features/membership/presentation/screens/membership_plan_details.screen.dart';
import '/features/membership/presentation/screens/membership_plan_management.screen.dart';
import '/features/notifications/presentation/screens/notification_management.screen.dart';
import '/features/services/presentation/screens/services_management.screen.dart';
import '/features/settings/presentation/screens/admin_settings.screen.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/presentation/screens/user_details.screen.dart';
import '/features/users/presentation/screens/users_management.screen.dart';

final class AppRouter {
  AppRouter._();

  static final goRouterProvider = Provider<GoRouter>((ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final authRefresh = ref.read(authRefreshProvider);

    final router = GoRouter(
      initialLocation: LoginScreen.route,
      refreshListenable: authRefresh,
      errorPageBuilder: (context, state) =>
          const NoTransitionPage(child: NotFoundScreen()),

      redirect: (context, state) {
        final isAuthenticated = authRepository.isAuthenticated;

        final isLoginRoute = state.matchedLocation == LoginScreen.route;
        final isDownloadRoute =
            state.matchedLocation == PublicDownloadScreen.route;
        final isPublicRoute =
            isDownloadRoute ||
            state.matchedLocation.startsWith(PublicLegalScreen.pathPrefix);

        // Not logged in and accessing protected route
        if (!isAuthenticated && !isLoginRoute && !isPublicRoute) {
          return LoginScreen.route;
        }

        // Logged in and accessing login
        if (isAuthenticated && isLoginRoute) {
          return DashboardScreen.route;
        }

        return null;
      },

      routes: [
        GoRoute(
          path: PublicDownloadScreen.route,
          builder: (context, state) => const PublicDownloadScreen(),
        ),

        GoRoute(
          path: LoginScreen.route,
          builder: (context, state) => const LoginScreen(),
        ),

        GoRoute(
          path: PublicLegalScreen.route,
          builder: (context, state) {
            final contentType =
                ContentType.tryFromSlug(state.pathParameters['contentType']) ??
                ContentType.terms;
            final role =
                UserRoleType.tryFromSlug(state.pathParameters['role']) ??
                UserRoleType.customer;
            final language =
                LanguageType.tryFromString(state.pathParameters['language']) ??
                LanguageType.english;
            return PublicLegalScreen(
              initialContentType: contentType,
              initialRole: role,
              initialLanguage: language,
            );
          },
        ),

        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdminShell(navigationShell: navigationShell);
          },
          branches: [
            // 1. Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: DashboardScreen.route,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),

            // 2. Users: /users/<role>/<status> for every list in
            //    UsersManagementScreen.listsByRole, plus /users/detail/:id.
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: UsersManagementScreen.route,
                  redirect: (context, state) =>
                      state.uri.path == UsersManagementScreen.route
                      ? UsersManagementScreen.defaultLocation
                      : null,
                  routes: [
                    for (final MapEntry(key: role, value: statuses)
                        in UsersManagementScreen.listsByRole.entries)
                      GoRoute(
                        path: role.slug,
                        redirect: (context, state) =>
                            state.uri.path ==
                                UsersManagementScreen.roleLocation(role)
                            ? UsersManagementScreen.location(
                                role,
                                UsersManagementScreen.defaultStatus,
                              )
                            : null,
                        routes: [
                          for (final status in statuses)
                            GoRoute(
                              path: status.slug,
                              builder: (context, state) =>
                                  UsersManagementScreen(
                                    role: role,
                                    status: status,
                                  ),
                            ),
                        ],
                      ),
                    GoRoute(
                      path: UserDetailsScreen.path,
                      builder: (context, state) => UserDetailsScreen(
                        userId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 3. Services
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: ServicesManagementScreen.route,
                  builder: (context, state) => const ServicesManagementScreen(),
                ),
              ],
            ),

            // 4. Document types
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: DocumentTypeManagementScreen.route,
                  builder: (context, state) =>
                      const DocumentTypeManagementScreen(),
                ),
              ],
            ),

            // 5. Membership plans
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: MembershipPlanManagementScreen.route,
                  builder: (context, state) =>
                      const MembershipPlanManagementScreen(),
                  routes: [
                    GoRoute(
                      path: MembershipPlanDetailsScreen.path,
                      builder: (context, state) => MembershipPlanDetailsScreen(
                        planId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 6. Settings
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AdminSettingsScreen.route,
                  builder: (context, state) => const AdminSettingsScreen(),
                ),
              ],
            ),

            // 7. Notifications
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: NotificationManagementScreen.route,
                  builder: (context, state) =>
                      const NotificationManagementScreen(),
                ),
              ],
            ),

            // 8. Help & Support + FAQs
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: HelpSupportManagementScreen.route,
                  builder: (context, state) =>
                      const HelpSupportManagementScreen(),
                ),
                GoRoute(
                  path: FaqManagementScreen.route,
                  builder: (context, state) => const FaqManagementScreen(),
                  routes: [
                    GoRoute(
                      path: FaqFormScreen.addPath,
                      builder: (context, state) => const FaqFormScreen(),
                    ),
                    GoRoute(
                      path: FaqFormScreen.editPath,
                      builder: (context, state) {
                        final faq = state.extra as Faq?;
                        return FaqFormScreen(faq: faq);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // 9. Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: ProfileScreen.route,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),

            // 10. Policies & legal content: /content/<type>
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: ContentManagementScreen.route,
                  redirect: (context, state) =>
                      state.uri.path == ContentManagementScreen.route
                      ? ContentManagementScreen.location(ContentType.terms)
                      : null,
                  routes: [
                    for (final type in ContentType.values)
                      GoRoute(
                        path: type.slug,
                        builder: (context, state) => ContentManagementScreen(
                          key: ValueKey(type),
                          initialType: type,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return router;
  });
}
