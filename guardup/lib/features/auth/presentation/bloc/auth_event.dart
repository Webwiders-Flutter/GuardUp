part of 'auth_bloc.dart';

abstract class AuthEvent {
  const AuthEvent();
  List<Object?> get props => [];
}

class AuthStatusChanged extends AuthEvent {
  final AuthStatus status;
  const AuthStatusChanged(this.status);
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested({required this.email, required this.password});
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String phoneCode;
  final String countryCode;
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.phoneCode,
    required this.countryCode,
  });
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;
  const AuthForgotPasswordRequested({required this.email});
}

class AuthUpdatePasswordRequested extends AuthEvent {
  final String newPassword;
  final String? oldPassword;
  const AuthUpdatePasswordRequested({
    required this.newPassword,
    this.oldPassword,
  });
}

class AuthUpdateEmailRequested extends AuthEvent {
  final String newEmail;
  final bool isResend;
  const AuthUpdateEmailRequested({
    required this.newEmail,
    this.isResend = false,
  });
}

class AuthVerifyEmailUpdateRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthVerifyEmailUpdateRequested({
    required this.email,
    required this.token,
  });
}

class AuthUpdatePhoneRequested extends AuthEvent {
  final String newPhone;
  final String phoneCode;
  final String countryCode;
  const AuthUpdatePhoneRequested({
    required this.newPhone,
    required this.phoneCode,
    required this.countryCode,
  });
}

class AuthVerifyPhoneUpdateRequested extends AuthEvent {
  final String phone;
  final String token;
  final String phoneCode;
  final String countryCode;
  const AuthVerifyPhoneUpdateRequested({
    required this.phone,
    required this.token,
    required this.phoneCode,
    required this.countryCode,
  });
}

class AuthVerifySignupPhoneRequested extends AuthEvent {
  final String phone;
  final String token;
  final String phoneCode;
  final String countryCode;
  const AuthVerifySignupPhoneRequested({
    required this.phone,
    required this.token,
    required this.phoneCode,
    required this.countryCode,
  });
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthDeleteAccountRequested extends AuthEvent {
  final String password;
  const AuthDeleteAccountRequested({required this.password});
}

class AuthRefreshEvent extends AuthEvent {
  const AuthRefreshEvent();
}

class AuthVerifySignupEmailRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthVerifySignupEmailRequested({
    required this.email,
    required this.token,
  });
  @override
  List<Object?> get props => [email, token];
}

class AuthVerifyPasswordRecoveryOtpRequested extends AuthEvent {
  final String email;
  final String token;
  const AuthVerifyPasswordRecoveryOtpRequested({
    required this.email,
    required this.token,
  });
  @override
  List<Object?> get props => [email, token];
}

class AuthResendSignupEmailRequested extends AuthEvent {
  final String email;
  const AuthResendSignupEmailRequested({required this.email});
  @override
  List<Object?> get props => [email];
}
