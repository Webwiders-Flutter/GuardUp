import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../data/enum/gender_type.enum.dart';
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
  final Map<String, dynamic>? userData;

  const AuthState({
    this.sessionStatus = AuthSessionStatus.unknown,
    this.operationState = const ApiState.initial(),
    this.status = UserStatus.incomplete,
    this.email,
    this.phoneCode,
    this.phoneNumber,
    this.userData,
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
    Map<String, dynamic>? userData,
  }) : this(
         sessionStatus: AuthSessionStatus.unauthenticated,
         operationState: operationState,
         status: status,
         email: email,
         phoneCode: phoneCode,
         phoneNumber: phoneNumber,
         userData: userData,
       );

  AuthState.authenticated(
    UserModel user, {
    ApiState<UserModel>? operationState,
    UserStatus? status,
    String? email,
    String? phoneCode,
    String? phoneNumber,
    Map<String, dynamic>? userData,
  }) : this(
         sessionStatus: AuthSessionStatus.authenticated,
         operationState: operationState ?? ApiSuccess(user),
         status: status ?? (user.role == UserRole.customer ? UserStatus.active : UserStatus.incomplete),
         email: email,
         phoneCode: phoneCode,
         phoneNumber: phoneNumber,
         userData: userData,
       );

  bool get isAuthenticated => sessionStatus == AuthSessionStatus.authenticated;
  bool get isUnauthenticated =>
      sessionStatus == AuthSessionStatus.unauthenticated;
  bool get isUnknown => sessionStatus == AuthSessionStatus.unknown;

  UserModel? get user => operationState.dataOrNull;
  UserRole get sessionRole => user?.role ?? UserRole.customer;
  bool get isLoading => operationState.isLoading;
  bool get hasError => operationState.isFailure;
  String? get errorMessage => operationState.errorMessageOrNull;

  // ── Database Users Table Getters (Single Source of Truth) ──────────────────
  String get displayName =>
      (userData?['company_name'] as String?)?.trim().isNotEmpty == true
          ? userData!['company_name'] as String
          : ((userData?['name'] as String?) ?? user?.name ?? '');

  String get companyName =>
      (userData?['company_name'] as String?)?.trim().isNotEmpty == true
          ? userData!['company_name'] as String
          : ((userData?['name'] as String?) ?? user?.name ?? 'Security Company');

  String get companyType => (userData?['company_type'] as String?) ?? '';

  String get businessEmail =>
      (userData?['business_email'] as String?) ??
      (userData?['email'] as String?) ??
      email ??
      '';

  String get companyPhoneNumber =>
      (userData?['company_phone_number'] as String?) ?? '';

  String get companyPhoneCode =>
      (userData?['company_phone_code'] as String?) ?? '+91';

  String get displayPhone {
    if (isCompany && companyPhoneNumber.isNotEmpty) {
      return '$companyPhoneCode $companyPhoneNumber';
    }
    final p = userPhoneNumber;
    if (p.isNotEmpty) {
      return '$userPhoneCode $p';
    }
    return '';
  }

  String get userPhoneNumber =>
      (userData?['phone_number'] as String?) ?? phoneNumber ?? '';

  String get userPhoneCode =>
      (userData?['phone_code'] as String?) ?? phoneCode ?? '+91';

  num get hourlyRate =>
      num.tryParse(userData?['hourly_rate']?.toString() ?? '0') ?? 0;

  double get rating =>
      double.tryParse(userData?['rating']?.toString() ?? '4.95') ?? 4.95;

  String get bio => (userData?['bio'] as String?) ?? '';

  List<String> get services {
    final list = userData?['services'] as List<dynamic>?;
    if (list != null && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    final meta = userData?['metadata'];
    if (meta is Map && meta['services'] is List) {
      return (meta['services'] as List).map((e) => e.toString()).toList();
    }
    return const [];
  }

  String get avatarUrl =>
      (userData?['profile_image_url'] as String?) ??
      user?.profileImageUrl ??
      '';

  String? get gender =>
      (userData?['gender'] as String?) ??
      (userData?['metadata'] is Map
          ? (userData!['metadata'] as Map)['gender'] as String?
          : null);

  GenderType get genderType => GenderType.fromApiValue(gender);

  String get address =>
      (userData?['address'] as String?) ??
      (userData?['metadata'] is Map
          ? (userData!['metadata'] as Map)['address'] as String?
          : null) ??
      '';

  double? get latitude {
    final raw = userData?['latitude'] ??
        (userData?['metadata'] is Map
            ? (userData!['metadata'] as Map)['latitude']
            : null);
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  double? get longitude {
    final raw = userData?['longitude'] ??
        (userData?['metadata'] is Map
            ? (userData!['metadata'] as Map)['longitude']
            : null);
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  int get experienceYears {
    final raw = userData?['experience_years'] ??
        (userData?['metadata'] is Map
            ? (userData!['metadata'] as Map)['experience_years']
            : null);
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  String get experienceYearsFormatted {
    final yrs = experienceYears;
    return yrs > 0 ? '$yrs+ Yrs Exp' : '0 Yrs Exp';
  }

  String get languages =>
      (userData?['languages'] as String?) ??
      (userData?['metadata'] is Map
          ? (userData!['metadata'] as Map)['languages'] as String?
          : null) ??
      '';

  String get certifications =>
      (userData?['certifications'] as String?) ??
      (userData?['metadata'] is Map
          ? (userData!['metadata'] as Map)['certifications'] as String?
          : null) ??
      '';

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
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      operationState: operationState ?? this.operationState,
      status: status ?? this.status,
      email: email ?? this.email,
      phoneCode: phoneCode ?? this.phoneCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userData: userData ?? this.userData,
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
    userData,
  ];
}
