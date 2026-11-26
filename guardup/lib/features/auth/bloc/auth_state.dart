import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/features/body_guard/data/model/user_document.model.dart';
import '/features/company/data/model/company.model.dart';
import '/features/services/data/models/service.model.dart';
import '../data/enum/user_role.enum.dart';
import '../data/enum/user_status.enum.dart';
import '../data/model/user.model.dart';

/// The single source of truth for global session authentication.
enum AuthSessionStatus { unknown, authenticated, unauthenticated }

/// Represents the authentication state of the application across all 3 roles:
/// - Customer
/// - Guard (Bodyguard)
/// - Company (Security Company)
class AuthState extends Equatable {
  final AuthSessionStatus sessionStatus;
  final ApiState<UserModel> operationState;
  final UserStatus status;
  final String? email;
  final String? phoneCode;
  final String? phoneNumber;
  final UserRole? pendingRole;
  final String? pendingEmail;
  final List<ServiceModel> userServices;
  final List<UserDocumentModel> userDocuments;

  const AuthState({
    this.sessionStatus = AuthSessionStatus.unknown,
    this.operationState = const ApiState.initial(),
    this.status = UserStatus.incomplete,
    this.email,
    this.phoneCode,
    this.phoneNumber,
    this.pendingRole,
    this.pendingEmail,
    this.userServices = const [],
    this.userDocuments = const [],
  });

  const AuthState.unknown()
    : this(
        sessionStatus: AuthSessionStatus.unknown,
        operationState: const ApiState.initial(),
        status: UserStatus.incomplete,
      );

  const AuthState.unauthenticated({
    ApiState<UserModel> operationState = const ApiState.initial(),
    UserStatus status = UserStatus.incomplete,
    String? email,
    String? phoneCode,
    String? phoneNumber,
    UserRole? pendingRole,
    String? pendingEmail,
    List<ServiceModel> userServices = const [],
    List<UserDocumentModel> userDocuments = const [],
  }) : this(
         sessionStatus: AuthSessionStatus.unauthenticated,
         operationState: operationState,
         status: status,
         email: email,
         phoneCode: phoneCode,
         phoneNumber: phoneNumber,
         pendingRole: pendingRole,
         pendingEmail: pendingEmail,
         userServices: userServices,
         userDocuments: userDocuments,
       );

  AuthState.authenticated(
    UserModel user, {
    ApiState<UserModel>? operationState,
    UserStatus? status,
    String? email,
    String? phoneCode,
    String? phoneNumber,
    UserRole? pendingRole,
    String? pendingEmail,
    List<ServiceModel>? userServices,
    List<UserDocumentModel>? userDocuments,
  }) : this(
         sessionStatus: AuthSessionStatus.authenticated,
         operationState: operationState ?? ApiSuccess(user),
         status:
             status ??
             (user.role == UserRole.customer ? UserStatus.active : user.status),
         email: email ?? (user.email.isNotEmpty ? user.email : null),
         phoneCode: phoneCode ?? user.phoneCode,
         phoneNumber: phoneNumber ?? user.phoneNumber,
         pendingRole: pendingRole,
         pendingEmail: pendingEmail,
         userServices: userServices ?? user.serviceListData ?? const [],
         userDocuments: userDocuments ?? user.documents ?? const [],
       );

  bool get isAuthenticated => sessionStatus == AuthSessionStatus.authenticated;
  bool get isUnauthenticated =>
      sessionStatus == AuthSessionStatus.unauthenticated;
  bool get isUnknown => sessionStatus == AuthSessionStatus.unknown;

  UserModel? get user => operationState.dataOrNull;

  BodyGuardModel? get guardProfile {
    final bg = user?.bodyguard;
    if (bg == null) return null;
    if ((bg.availabilities == null || bg.availabilities!.isEmpty) &&
        user?.availabilities != null &&
        user!.availabilities!.isNotEmpty) {
      return bg.copyWith(availabilities: user!.availabilities);
    }
    return bg;
  }

  CompanyModel? get companyProfile => user?.company;

  UserRole get sessionRole => user?.role ?? pendingRole ?? UserRole.customer;
  UserRole get role => sessionRole;
  bool get isLoading => operationState.isLoading;
  bool get hasError => operationState.isFailure;
  String? get errorMessage => operationState.errorMessageOrNull;

  // ── Role Helpers ────────────────────────────────────────────────────────────
  bool get isCustomer => sessionRole == UserRole.customer;
  bool get isGuard => sessionRole == UserRole.guard;
  bool get isCompany => sessionRole == UserRole.company;

  // ── Onboarding & Approval Helpers ──────────────────────────────────────────
  /// Whether the user has full clearance to use the app dashboard:
  /// - Customers are active immediately upon email verification.
  /// - Guards and Companies require admin approval.
  bool get isApproved => status == UserStatus.active;

  /// Whether the guard/company has completed submissions and is waiting for admin verification.
  bool get isPendingApproval => status == UserStatus.pendingApproval;

  /// Whether the account has been blocked or suspended by administrator.
  bool get isBlocked => status == UserStatus.blocked;

  /// Whether the account has been soft-deleted or deactivated by administrator.
  bool get isDeleted => status == UserStatus.deleted;

  /// Whether the application was rejected by administrator.
  bool get isRejected => status == UserStatus.rejected;

  /// The administrator profile rejection reason from `users` table.
  String? get profileRejectionReason => user?.rejectionReason;

  /// The user's active membership plan ID from `users` table or metadata.
  String? get membershipPlanId =>
      user?.metadata?['membership_plan_id'] as String?;

  /// Backwards compatibility getter for profile rejection reason.
  String? get rejectionReason => profileRejectionReason;

  /// Whether the profile itself was rejected (reason in `users` table).
  bool get isProfileRejected => isRejected && profileRejectionReason != null;

  /// Whether one or more documents were rejected (status == REJECTED in `user_documents`).
  bool get hasRejectedDocuments =>
      userDocuments.any((doc) => doc.status == DocumentStatus.rejected);

  /// Whether both profile and documents are rejected.
  bool get isBothProfileAndDocumentRejected =>
      isProfileRejected && hasRejectedDocuments;

  /// Whether ONLY the profile is rejected (no documents rejected).
  bool get isOnlyProfileRejected =>
      isRejected && isProfileRejected && !hasRejectedDocuments;

  /// Whether ONLY document(s) are rejected (no profile rejection reason).
  bool get isOnlyDocumentRejected =>
      isRejected && hasRejectedDocuments && !isProfileRejected;

  /// Whether the guard or company still needs to finish onboarding steps
  /// (profile information, documents upload, registration fee).
  bool get requiresOnboarding => status == UserStatus.incomplete;

  AuthState copyWith({
    AuthSessionStatus? sessionStatus,
    ApiState<UserModel>? operationState,
    UserStatus? status,
    String? email,
    String? phoneCode,
    String? phoneNumber,
    UserRole? pendingRole,
    String? pendingEmail,
    List<ServiceModel>? userServices,
    List<UserDocumentModel>? userDocuments,
  }) {
    return AuthState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      operationState: operationState ?? this.operationState,
      status: status ?? this.status,
      email: email ?? this.email,
      phoneCode: phoneCode ?? this.phoneCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      pendingRole: pendingRole ?? this.pendingRole,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      userServices: userServices ?? this.userServices,
      userDocuments: userDocuments ?? this.userDocuments,
    );
  }

  @override
  List<Object?> get props => [
    sessionStatus,
    operationState,
    status,
    email,
    phoneCode,
    phoneNumber,
    pendingRole,
    pendingEmail,
    userServices,
    userDocuments,
  ];
}
