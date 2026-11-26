import 'package:equatable/equatable.dart';

import '../../data/enum/otp_type.enum.dart';
import '../../data/enum/user_role.enum.dart';

/// Events dispatched to [AuthFormBloc].
sealed class AuthFormEvent extends Equatable {
  const AuthFormEvent();

  @override
  List<Object?> get props => [];
}

/// Attempts email + password sign-in.
final class LoginSubmitted extends AuthFormEvent {
  const LoginSubmitted({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Checks registration conflicts and registers a new account.
final class SignUpSubmitted extends AuthFormEvent {
  const SignUpSubmitted({
    required this.email,
    required this.password,
    required this.role,
    this.name,
    this.phone,
    this.phoneCode,
  });

  final String email;
  final String password;
  final UserRole role;
  final String? name;
  final String? phone;
  final String? phoneCode;

  @override
  List<Object?> get props => [email, password, role, name, phone, phoneCode];
}

/// Verifies a 6-digit OTP code for email/SMS/recovery flows.
final class OtpSubmitted extends AuthFormEvent {
  const OtpSubmitted({
    required this.email,
    required this.token,
    this.type = OtpType.email,
  });

  final String email;
  final String token;
  final OtpType type;

  @override
  List<Object?> get props => [email, token, type];
}

/// Resends an OTP code for the given target and type.
final class OtpResendRequested extends AuthFormEvent {
  const OtpResendRequested({
    required this.target,
    this.type = OtpType.email,
  });

  final String target;
  final OtpType type;

  @override
  List<Object?> get props => [target, type];
}

/// Verifies email existence and sends a password reset code.
final class PasswordResetCodeRequested extends AuthFormEvent {
  const PasswordResetCodeRequested({
    required this.email,
    this.emailNotFoundFallback,
  });

  final String email;
  final String? emailNotFoundFallback;

  @override
  List<Object?> get props => [email, emailNotFoundFallback];
}

/// Sets a new password and signs out of the recovery session.
final class NewPasswordSubmitted extends AuthFormEvent {
  const NewPasswordSubmitted({required this.newPassword});

  final String newPassword;

  @override
  List<Object?> get props => [newPassword];
}
