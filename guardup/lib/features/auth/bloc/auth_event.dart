import 'package:equatable/equatable.dart';

import '/features/body_guard/data/model/service_item.model.dart';
import '/features/body_guard/data/model/user_document.model.dart';
import '../data/enum/otp_type.enum.dart';
import '../data/enum/user_role.enum.dart';
import '../data/enum/user_status.enum.dart';
import '../data/model/user.model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on startup or refresh to check the initial authentication state.
class AuthCheckStatusRequested extends AuthEvent {
  const AuthCheckStatusRequested();
}

/// Internal event dispatched when the auth backend stream emits a user ID change.
class AuthUserChanged extends AuthEvent {
  final String? userId;

  const AuthUserChanged(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Internal event dispatched when the user profile stream emits an update.
class AuthProfileChanged extends AuthEvent {
  final UserModel? profile;
  final UserStatus? status;
  final String? email;
  final Map<String, dynamic>? userData;

  const AuthProfileChanged(
    this.profile, {
    this.status,
    this.email,
    this.userData,
  });

  @override
  List<Object?> get props => [profile, status, email, userData];
}

/// Internal event dispatched when an error occurs on a background stream.
class AuthErrorOccurred extends AuthEvent {
  final String message;

  const AuthErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}

/// Dispatched when a user attempts to log in with email and password.
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Dispatched when a new user registers with email, password, optional name, phone, and role.
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? name;
  final String? phone;
  final String? phoneCode;
  final UserRole role;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.name,
    this.phone,
    this.phoneCode,
    this.role = UserRole.customer,
  });

  @override
  List<Object?> get props => [email, password, name, phone, phoneCode, role];
}

/// Dispatched when user submits an OTP code received via email or SMS.
class AuthVerifyOtpRequested extends AuthEvent {
  final String email;
  final String token;
  final OtpType type;

  const AuthVerifyOtpRequested({
    required this.email,
    required this.token,
    this.type = OtpType.email,
  });

  @override
  List<Object?> get props => [email, token, type];
}

/// Dispatched when requesting a fresh OTP code.
class AuthResendOtpRequested extends AuthEvent {
  final String target;
  final OtpType type;

  const AuthResendOtpRequested({
    required this.target,
    this.type = OtpType.email,
  });

  @override
  List<Object?> get props => [target, type];
}

/// Dispatched when the user transitions status (e.g., incomplete -> pendingApproval -> approved).
class AuthUpdateUserStatusRequested extends AuthEvent {
  final UserStatus status;

  const AuthUpdateUserStatusRequested(this.status);

  @override
  List<Object?> get props => [status];
}

/// Dispatched when the user updates profile details.
class AuthUpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? profileImageUrl;

  const AuthUpdateProfileRequested({this.name, this.profileImageUrl});

  @override
  List<Object?> get props => [name, profileImageUrl];
}

/// Dispatched when the user selects a role during onboarding/flow to persist in session.
class AuthSetSessionRoleRequested extends AuthEvent {
  final UserRole role;

  const AuthSetSessionRoleRequested(this.role);

  @override
  List<Object?> get props => [role];
}

/// Dispatched when a user requests a password reset code to their email.
class AuthSendPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthSendPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Dispatched when user sets a new password during the recovery flow.
class AuthResetPasswordRequested extends AuthEvent {
  final String newPassword;

  const AuthResetPasswordRequested({required this.newPassword});

  @override
  List<Object?> get props => [newPassword];
}

/// Dispatched when the user logs out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Dispatched when the user permanently deletes their account.
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}

/// Dispatched to refresh user services and documents according to their role.
class AuthReloadRoleDataRequested extends AuthEvent {
  const AuthReloadRoleDataRequested();
}

/// Dispatched to update user services in the global auth state.
class AuthUpdateUserServices extends AuthEvent {
  final List<ServiceItemModel> services;

  const AuthUpdateUserServices(this.services);

  @override
  List<Object?> get props => [services];
}

/// Dispatched to update user documents in the global auth state.
class AuthUpdateUserDocuments extends AuthEvent {
  final List<UserDocumentModel> documents;

  const AuthUpdateUserDocuments(this.documents);

  @override
  List<Object?> get props => [documents];
}
