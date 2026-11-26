import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/auth_refresh_listenable.dart';
import '/app/routes/redirect.dart';
import '/app/screens/main_navigation.screen.dart';
import '/app/screens/not_found_screen.dart';
import '/core/di/injection_container.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/booking/booking.dart';
import '/features/chat/chat.dart';
import '/features/company/company.dart';
import '/features/customer/customer.dart';
import '/features/legal/legal.dart';
import '/features/notifications/notifications.dart';
import '/features/payments/payments.dart';
import '/core/utils/json_converters/enum.jsonconverter.dart';

BodyGuardModel? _parseBodyGuard(dynamic extra) {
  if (extra is BodyGuardModel) return extra;
  if (extra is Map) {
    try {
      final map = Map<String, dynamic>.from(extra);
      if (map['bodyguard'] is BodyGuardModel) {
        return map['bodyguard'] as BodyGuardModel;
      }
      if (map['bodyguard'] is Map) {
        try {
          return BodyGuardModel.fromJson(
              Map<String, dynamic>.from(map['bodyguard'] as Map));
        } catch (_) {}
      }
      return BodyGuardModel.fromJson(map);
    } catch (_) {}
  }
  return null;
}

CompanyModel? _parseCompany(dynamic extra) {
  if (extra is CompanyModel) return extra;
  if (extra is Map) {
    try {
      final map = Map<String, dynamic>.from(extra);
      if (map['company'] is CompanyModel) {
        return map['company'] as CompanyModel;
      }
      if (map['company'] is Map) {
        try {
          return CompanyModel.fromJson(
              Map<String, dynamic>.from(map['company'] as Map));
        } catch (_) {}
      }
      return CompanyModel.fromJson(map);
    } catch (_) {}
  }
  return null;
}

ConversationModel? _parseConversation(dynamic extra) {
  if (extra is ConversationModel) return extra;
  if (extra is Map) {
    try {
      return ConversationModel.fromJson(Map<String, dynamic>.from(extra));
    } catch (_) {}
  }
  return null;
}

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
    initialLocation: SplashScreen.route,
    refreshListenable: refreshListenable,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) async => resolveRedirect(
      authState: sl<AuthBloc>().state,
      location: state.matchedLocation,
    ),

    routes: [
      GoRoute(
        path: SplashScreen.route,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: SelectRoleScreen.route,
        builder: (context, state) => const SelectRoleScreen(),
      ),
      GoRoute(
        path: CompanyCompleteProfileScreen.route,
        builder: (context, state) => const CompanyCompleteProfileScreen(),
      ),
      GoRoute(
        path: BodyGuardCompleteProfileScreen.route,
        builder: (context, state) {
          final bodyguard = _parseBodyGuard(state.extra);
          return BodyGuardCompleteProfileScreen(bodyguard: bodyguard);
        },
      ),
      GoRoute(
        path: BodyGuardUploadDocumentsScreen.route,
        builder: (context, state) {
          final bodyguard = _parseBodyGuard(state.extra);
          return BodyGuardUploadDocumentsScreen(bodyguard: bodyguard);
        },
      ),
      GoRoute(
        path: LoginScreen.route,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: SignUpScreen.route,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: ForgotPasswordScreen.route,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: EmailVerificationScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          String? email;
          UserRole? role;
          OtpType otpType = OtpType.email;

          if (extra is Map) {
            email = extra['email'] as String?;
            role = extra['role'] as UserRole?;
            final rawOtpType = extra['otpType'];
            if (rawOtpType is OtpType) {
              otpType = rawOtpType;
            } else if (rawOtpType is String) {
              otpType = OtpType.values.fromValue(rawOtpType) ?? otpType;
            }
          } else if (extra is String) {
            email = extra;
          }

          email ??= state.uri.queryParameters['email'];
          final queryType = state.uri.queryParameters['type'];
          if (queryType != null) {
            otpType = OtpType.values.fromValue(queryType) ?? otpType;
          }

          return EmailVerificationScreen(
            email: email,
            role: role,
            otpType: otpType,
          );
        },
      ),
      GoRoute(
        path: ResetPasswordScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          String? email;
          if (extra is String) {
            email = extra;
          } else if (extra is Map) {
            email = extra['email'] as String?;
          }
          email ??= state.uri.queryParameters['email'];
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: UploadDocumentsScreen.route,
        builder: (context, state) => const UploadDocumentsScreen(),
      ),
      GoRoute(
        path: RegistrationFeeScreen.route,
        builder: (context, state) => const RegistrationFeeScreen(),
      ),
      GoRoute(
        path: PaymentSuccessScreen.route,
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
          if (extra is Map) {
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
        path: AdminApprovalScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is BodyGuardModel) {
            return AdminApprovalScreen(
              bodyguard: extra,
              isCompanyBodyguardFlow: true,
            );
          } else if (extra is Map) {
            return AdminApprovalScreen(
              bodyguard: _parseBodyGuard(extra),
              isCompanyBodyguardFlow:
                  extra['isCompanyBodyguardFlow'] as bool? ?? false,
            );
          }
          return const AdminApprovalScreen();
        },
      ),
      GoRoute(
        path: AccountStatusScreen.blockedRoute,
        builder: (context, state) =>
            const AccountStatusScreen(isDeleted: false),
      ),
      GoRoute(
        path: AccountStatusScreen.deletedRoute,
        builder: (context, state) => const AccountStatusScreen(isDeleted: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home — every role shares `/home`; the screen is chosen
          // by session role below.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CustomerHomeScreen.route,
                builder: (context, state) => BlocBuilder<AuthBloc, AuthState>(
                  bloc: sl.isRegistered<AuthBloc>() ? sl<AuthBloc>() : null,
                  builder: (context, authState) {
                    switch (authState.sessionRole) {
                      case UserRole.company:
                        return const CompanyHomeScreen(
                          key: ValueKey(UserRole.company),
                        );
                      case UserRole.guard:
                        return const BodyGuardHomeScreen(
                          key: ValueKey(UserRole.guard),
                        );
                      case UserRole.customer:
                        return const CustomerHomeScreen(
                          key: ValueKey(UserRole.customer),
                        );
                    }
                  },
                ),
              ),
            ],
          ),

          // Branch 1: Bookings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: BookingsScreen.route,
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),

          // Branch 2: Chat
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ConversationsScreen.route,
                builder: (context, state) => BlocBuilder<AuthBloc, AuthState>(
                  bloc: sl.isRegistered<AuthBloc>() ? sl<AuthBloc>() : null,
                  builder: (context, authState) {
                    if (authState.sessionRole == UserRole.guard) {
                      return const GuardChatListScreen(
                        key: ValueKey(UserRole.guard),
                      );
                    }
                    return const ConversationsScreen(
                      key: ValueKey('customer_company_chat'),
                    );
                  },
                ),
              ),
            ],
          ),

          // Branch 3: Alerts / Notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: NotificationsScreen.route,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ProfileScreen.route,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: EditProfileScreen.route,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: CompanyEditProfileScreen.route,
        builder: (context, state) => const CompanyEditProfileScreen(),
      ),
      GoRoute(
        path: CompanyInformationScreen.route,
        builder: (context, state) => const CompanyInformationScreen(),
      ),
      GoRoute(
        path: CompanyDocumentsScreen.route,
        builder: (context, state) => const CompanyDocumentsScreen(),
      ),
      GoRoute(
        path: BodyguardsListScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          int initialTab = 0;
          BodyguardFilters? initialFilters;
          bool focusSearch = false;
          if (extra is int) {
            initialTab = extra;
          } else if (extra is BodyguardFilters) {
            initialFilters = extra;
          } else if (extra is Map) {
            if (extra['initialTab'] is int) {
              initialTab = extra['initialTab'] as int;
            }
            if (extra['initialFilters'] is BodyguardFilters) {
              initialFilters = extra['initialFilters'] as BodyguardFilters;
            }
            if (extra['focusSearch'] is bool) {
              focusSearch = extra['focusSearch'] as bool;
            }
          }
          return BodyguardsListScreen(
            initialTabIndex: initialTab,
            initialFilters: initialFilters,
            focusSearch: focusSearch,
          );
        },
      ),
      GoRoute(
        path: CompanyDetailsScreen.route,
        builder: (context, state) {
          final company = _parseCompany(state.extra);
          return CompanyDetailsScreen(company: company);
        },
      ),
      GoRoute(
        path: BodyGuardProfileScreen.route,
        builder: (context, state) {
          final guard = _parseBodyGuard(state.extra);
          return BodyGuardProfileScreen(bodyguard: guard);
        },
      ),
      GoRoute(
        path: '/customer-bodyguard-profile',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is BodyGuardModel) {
            return GuardDetailScreen(
              id: extra.id,
              bodyguard: extra,
              isCompanyView: false,
            );
          } else if (extra is String) {
            return GuardDetailScreen(
              id: extra,
              isCompanyView: false,
            );
          }
          final pathId = state.pathParameters['id'] ?? '';
          return GuardDetailScreen(id: pathId, isCompanyView: false);
        },
      ),
      GoRoute(
        path: GuardDetailScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is BodyGuardModel) {
            return GuardDetailScreen(id: extra.id, bodyguard: extra);
          } else if (extra is String) {
            return GuardDetailScreen(id: extra);
          } else if (extra is Map) {
            final guard = _parseBodyGuard(extra);
            return GuardDetailScreen(
              id: (extra['id'] ?? guard?.id ?? '').toString(),
              bodyguard: guard,
              isCompanyView: extra['isCompanyView'] as bool?,
            );
          }
          final pathId = state.pathParameters['id'] ?? '';
          return GuardDetailScreen(id: pathId);
        },
      ),
      GoRoute(
        path: MyBankDetailsScreen.route,
        builder: (context, state) => const MyBankDetailsScreen(),
      ),
      GoRoute(
        path: MyWalletScreen.route,
        builder: (context, state) => const MyWalletScreen(),
      ),
      GoRoute(
        path: AllServicesScreen.route,
        builder: (context, state) => const AllServicesScreen(),
      ),
      GoRoute(
        path: SearchBodyguardsScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          BodyguardFilters? initialFilters;
          bool returnResult = false;
          bool lockCompany = false;
          if (extra is BodyguardFilters) {
            initialFilters = extra;
          } else if (extra is Map) {
            if (extra['initialFilters'] is BodyguardFilters) {
              initialFilters = extra['initialFilters'] as BodyguardFilters;
            }
            if (extra['returnResult'] is bool) {
              returnResult = extra['returnResult'] as bool;
            }
            if (extra['lockCompany'] is bool) {
              lockCompany = extra['lockCompany'] as bool;
            }
          }
          return SearchBodyguardsScreen(
            initialFilters: initialFilters,
            returnResult: returnResult,
            lockCompany: lockCompany,
          );
        },
      ),
      GoRoute(
        path: CompanyBodyguardsScreen.route,
        builder: (context, state) => const CompanyBodyguardsScreen(),
      ),
      GoRoute(
        path: ChatScreen.route,
        builder: (context, state) {
          final conversation = _parseConversation(state.extra);
          return ChatScreen(conversation: conversation);
        },
      ),
      GoRoute(
        path: ChangePasswordScreen.route,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: MembershipPlansScreen.route,
        builder: (context, state) {
          final queryModeStr = state.uri.queryParameters['mode'];
          final queryMode = queryModeStr != null
              ? MembershipPlanMode.values.fromValue(queryModeStr)
              : null;

          final extra = state.extra;
          MembershipPlanMode? mode = queryMode;
          double? bookingAmount;
          String? operativeName;
          String? activePlanId;

          if (extra is MembershipPlanMode) {
            mode ??= extra;
          } else if (extra is String) {
            mode ??= MembershipPlanMode.values.fromValue(extra);
          } else if (extra is MembershipPlanArgs) {
            mode ??= extra.mode;
            bookingAmount = extra.bookingAmount;
            operativeName = extra.operativeName;
            activePlanId = extra.activePlanId;
          } else if (extra is Map) {
            final rawMode = extra['mode'];
            if (rawMode is MembershipPlanMode) {
              mode ??= rawMode;
            } else if (rawMode is String) {
              mode ??= MembershipPlanMode.values.fromValue(rawMode);
            }
            bookingAmount = (extra['bookingAmount'] as num?)?.toDouble();
            operativeName = extra['operativeName'] as String?;
            activePlanId = extra['activePlanId'] as String?;
          } else if (extra is Record) {
            try {
              final dynamic r = extra;
              if (r.mode is MembershipPlanMode) {
                mode ??= r.mode as MembershipPlanMode;
              } else if (r.mode is String) {
                mode ??= MembershipPlanMode.values.fromValue(r.mode as String);
              }
              if (r.bookingAmount is num) {
                bookingAmount = (r.bookingAmount as num).toDouble();
              }
              if (r.operativeName is String) {
                operativeName = r.operativeName as String;
              }
              if (r.activePlanId is String) {
                activePlanId = r.activePlanId as String;
              }
            } catch (_) {}
          }

          final authState = sl.isRegistered<AuthBloc>()
              ? sl<AuthBloc>().state
              : null;

          // If not specified, default to onboarding if no plan is active, else profile
          final hasActivePlan = authState?.membershipPlanId != null &&
              authState!.membershipPlanId!.trim().isNotEmpty;

          mode ??= hasActivePlan
              ? MembershipPlanMode.profile
              : MembershipPlanMode.onboarding;

          activePlanId ??= authState?.membershipPlanId;

          return MembershipPlansScreen(
            mode: mode,
            bookingAmount: bookingAmount,
            operativeName: operativeName,
            activePlanId: activePlanId,
          );
        },
      ),
      GoRoute(
        path: LegalContentScreen.privacyPolicyRoute,
        builder: (context, state) {
          final role = state.extra is UserRole ? state.extra as UserRole : null;
          return LegalContentScreen(
            type: ContentType.privacyPolicy,
            role: role,
          );
        },
      ),
      GoRoute(
        path: LegalContentScreen.termsRoute,
        builder: (context, state) {
          final role = state.extra is UserRole ? state.extra as UserRole : null;
          return LegalContentScreen(
            type: ContentType.terms,
            role: role,
          );
        },
      ),
      GoRoute(
        path: BookingScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          CompanyModel? company;
          BodyGuardModel? guard;
          if (extra is CompanyModel) {
            company = extra;
          } else if (extra is BodyGuardModel) {
            guard = extra;
          } else if (extra
              is ({CompanyModel? company, BodyGuardModel? guard})) {
            company = extra.company;
            guard = extra.guard;
          } else if (extra is Map) {
            company = _parseCompany(extra);
            guard = _parseBodyGuard(extra);
          }
          return BookingScreen(company: company, initialBodyguard: guard);
        },
      ),
      GoRoute(
        path: CustomerBookingDetailsScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return CustomerBookingDetailsScreen(
              bodyguard: _parseBodyGuard(extra),
              startDate: extra['startDate'] as DateTime? ?? DateTime.now(),
              startTime:
                  extra['startTime'] as TimeOfDay? ??
                  const TimeOfDay(hour: 10, minute: 0),
              endDate: extra['endDate'] as DateTime? ?? DateTime.now(),
              endTime:
                  extra['endTime'] as TimeOfDay? ??
                  const TimeOfDay(hour: 14, minute: 0),
              durationHours: (extra['durationHours'] as num?)?.toInt() ?? 4,
              hourlyRate: (extra['hourlyRate'] as num?)?.toDouble() ?? 60.0,
            );
          }
          if (extra is BodyGuardModel) {
            return CustomerBookingDetailsScreen(
              bodyguard: extra,
              startDate: DateTime.now(),
              startTime: const TimeOfDay(hour: 10, minute: 0),
              endDate: DateTime.now(),
              endTime: const TimeOfDay(hour: 14, minute: 0),
            );
          }
          return CustomerBookingDetailsScreen(
            startDate: DateTime.now(),
            startTime: const TimeOfDay(hour: 10, minute: 0),
            endDate: DateTime.now(),
            endTime: const TimeOfDay(hour: 14, minute: 0),
          );
        },
      ),
      GoRoute(
        path: CustomerBookingConfirmedScreen.route,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map) {
            return CustomerBookingConfirmedScreen(
              bodyguard: _parseBodyGuard(extra),
              guardName: extra['guardName'] as String?,
              guardPhoto: extra['guardPhoto'] as String?,
              startDate: extra['startDate'] as DateTime?,
              startTime: extra['startTime'] as TimeOfDay?,
              endDate: extra['endDate'] as DateTime?,
              endTime: extra['endTime'] as TimeOfDay?,
              hourlyRate: (extra['hourlyRate'] as num?)?.toDouble(),
              bookingId: extra['bookingId'] as String?,
              onChatTap: extra['onChatTap'] as VoidCallback?,
              onTrackLiveTap: extra['onTrackLiveTap'] as VoidCallback?,
            );
          }
          if (extra is BodyGuardModel) {
            return CustomerBookingConfirmedScreen(bodyguard: extra);
          }
          return const CustomerBookingConfirmedScreen();
        },
      ),
      GoRoute(
        path: ContactUsScreen.route,
        builder: (context, state) => const ContactUsScreen(),
      ),
    ],
  );
}
