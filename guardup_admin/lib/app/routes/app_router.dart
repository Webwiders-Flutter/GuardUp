import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/app_routes.dart';
import '/app/routes/auth_refresh_listenable.dart';
import '/app/screens/admin_shell.dart';
import '/app/screens/not_found_screen.dart';
import '/core/enums/language.enum.dart';
import '/features/auth/di/auth.providers.dart';
import '/features/auth/presentation/screens/login.screen.dart';
import '/features/auth/presentation/screens/profile.screen.dart';
import '/features/dashboard/presentation/screens/dashboard.screen.dart';
import '/features/help-support/presentation/screens/help_support_management.screen.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/legal/data/models/faq.model.dart';
import '/features/legal/presentation/screens/content_management.screen.dart';
import '/features/legal/presentation/screens/faq.form.dart';
import '/features/legal/presentation/screens/faq_management.screen.dart';
import '/features/legal/presentation/screens/public_legal.screen.dart';
import '/features/notifications/presentation/screens/notification_management.screen.dart';
import '/features/settings/presentation/screens/admin_settings.screen.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/presentation/screens/user_details.screen.dart';
import '/features/users/presentation/screens/users_management.screen.dart';

final class AppRouter {
  AppRouter._();

  static final goRouterProvider = Provider<GoRouter>((ref) {
    final authRepository = ref.read(authRepositoryProvider);
    final authRefresh = ref.read(authRefreshProvider);

    final router = GoRouter(
      initialLocation: AppRoutes.login,
      refreshListenable: authRefresh,
      errorPageBuilder: (context, state) =>
          const NoTransitionPage(child: NotFoundScreen()),

      redirect: (context, state) {
        final isAuthenticated = authRepository.isAuthenticated;

        final isLoginRoute = state.matchedLocation == AppRoutes.login;
        final isPublicRoute = state.matchedLocation.startsWith('/public');

        // Not logged in and accessing protected route
        if (!isAuthenticated && !isLoginRoute && !isPublicRoute) {
          return AppRoutes.login;
        }

        // Logged in and accessing login
        if (isAuthenticated && isLoginRoute) {
          return AppRoutes.home;
        }

        return null;
      },

      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),

        GoRoute(
          path: AppRoutes.publicLegal,
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
                  path: AppRoutes.home,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),

            // 2. Users Management
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.users,
                  name: AppRoutes.users,
                  redirect: (context, state) {
                    if (state.uri.path == AppRoutes.users) {
                      return AppRoutes.userCustomer;
                    }
                    return null;
                  },
                  routes: [
                    // Customer
                    GoRoute(
                      path: 'customer',
                      name: 'customer',
                      redirect: (context, state) {
                        if (state.uri.path == AppRoutes.userCustomer) {
                          return AppRoutes.userCustomerVerified;
                        }
                        return null;
                      },
                      routes: [
                        GoRoute(
                          path: 'verified',
                          name: 'customer-verified',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.customer,
                                status: UserStatus.active,
                              ),
                        ),
                        GoRoute(
                          path: 'pending',
                          name: 'customer-pending',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.customer,
                                status: UserStatus.approvalPending,
                              ),
                        ),
                        GoRoute(
                          path: 'blocked',
                          name: 'customer-blocked',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.customer,
                                status: UserStatus.blocked,
                              ),
                        ),
                      ],
                    ),

                    // Bodyguard
                    GoRoute(
                      path: 'bodyguard',
                      name: 'bodyguard',
                      redirect: (context, state) {
                        if (state.uri.path == AppRoutes.userGuard) {
                          return AppRoutes.userGuardVerified;
                        }
                        return null;
                      },
                      routes: [
                        GoRoute(
                          path: 'verified',
                          name: 'bodyguard-verified',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.guard,
                                status: UserStatus.active,
                              ),
                        ),
                        GoRoute(
                          path: 'pending',
                          name: 'bodyguard-pending',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.guard,
                                status: UserStatus.approvalPending,
                              ),
                        ),
                        GoRoute(
                          path: 'blocked',
                          name: 'bodyguard-blocked',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.guard,
                                status: UserStatus.blocked,
                              ),
                        ),
                      ],
                    ),

                    // Company
                    GoRoute(
                      path: 'company',
                      name: 'company',
                      redirect: (context, state) {
                        if (state.uri.path == AppRoutes.userCompany) {
                          return AppRoutes.userCompanyVerified;
                        }
                        return null;
                      },
                      routes: [
                        GoRoute(
                          path: 'verified',
                          name: 'company-verified',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.company,
                                status: UserStatus.active,
                              ),
                        ),
                        GoRoute(
                          path: 'pending',
                          name: 'company-pending',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.company,
                                status: UserStatus.approvalPending,
                              ),
                        ),
                        GoRoute(
                          path: 'blocked',
                          name: 'company-blocked',
                          builder: (context, state) =>
                              const UsersManagementScreen(
                                role: UserRoleType.company,
                                status: UserStatus.blocked,
                              ),
                        ),
                      ],
                    ),

                    // User Detail
                    GoRoute(
                      path: 'detail/:id',
                      name: 'detail',
                      builder: (context, state) {
                        return UserDetailsScreen(
                          userId: state.pathParameters['id']!,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),

            // 3. Settings
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.settings,
                  builder: (context, state) => const AdminSettingsScreen(),
                ),
              ],
            ),

            // 4. Notifications
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.notifications,
                  builder: (context, state) =>
                      const NotificationManagementScreen(),
                ),
              ],
            ),

            // 5. Help & Support + FAQs
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.helpSupport,
                  builder: (context, state) =>
                      const HelpSupportManagementScreen(),
                ),
                GoRoute(
                  path: AppRoutes.faqs,
                  builder: (context, state) => const FaqManagementScreen(),
                  routes: [
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => const FaqFormScreen(),
                    ),
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) {
                        final faq = state.extra as Faq?;
                        return FaqFormScreen(faq: faq);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // 6. Profile Details
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profileDetails,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),

            // 7. Policies & Legal Content
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.content,
                  redirect: (context, state) {
                    if (state.uri.path == AppRoutes.content) {
                      return AppRoutes.contentUrl(ContentType.terms);
                    }
                    return null;
                  },
                  routes: ContentType.values
                      .map(
                        (e) => GoRoute(
                          path: e.slug,
                          builder: (context, state) => ContentManagementScreen(
                            key: ValueKey(e),
                            initialType: e,
                          ),
                        ),
                      )
                      .toList(),
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
