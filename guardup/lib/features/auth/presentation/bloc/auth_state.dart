part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {
  const AuthInitialState();
}

class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

class AuthDeleteAccountLoadingState extends AuthState {
  final UserEntity user;

  const AuthDeleteAccountLoadingState(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthDeleteAccountErrorState extends AuthState {
  final UserEntity user;
  final String message;

  const AuthDeleteAccountErrorState({
    required this.user,
    required this.message,
  });

  @override
  List<Object?> get props => [user, message];
}

class AuthDeleteAccountSuccessState extends AuthState {
  const AuthDeleteAccountSuccessState();
}

class AuthenticatedState extends AuthState {
  final UserEntity user;
  final int? timestamp;
  const AuthenticatedState(this.user, [this.timestamp]);

  @override
  List<Object?> get props => [user, timestamp];
}

class UnAuthenticatedState extends AuthState {
  const UnAuthenticatedState();
}

class AuthSignupSuccessState extends AuthState {
  const AuthSignupSuccessState();
}

class AuthSignupPhoneOtpSentState extends AuthState {
  final String email;
  final String phoneCode;
  final String countryCode;

  const AuthSignupPhoneOtpSentState(
    this.email,
    this.phoneCode,
    this.countryCode,
  );

  @override
  List<Object?> get props => [email, phoneCode, countryCode];
}

class AuthVerifySignupPhoneSuccessState extends AuthState {
  const AuthVerifySignupPhoneSuccessState();
}

class AuthEmailNotConfirmedState extends AuthState {
  const AuthEmailNotConfirmedState();
}

class AuthPasswordRecoveryState extends AuthState {
  const AuthPasswordRecoveryState();
  @override
  List<Object?> get props => [];
}

class AuthForgotPasswordSuccessState extends AuthState {
  const AuthForgotPasswordSuccessState();
}

class AuthUpdatePasswordSuccessState extends AuthState {
  const AuthUpdatePasswordSuccessState();
}

class AuthUpdateEmailSuccessState extends AuthState {
  const AuthUpdateEmailSuccessState();
}

class AuthUpdateEmailOtpSentState extends AuthState {
  final String email;
  final bool isResend;
  const AuthUpdateEmailOtpSentState(this.email, {this.isResend = false});

  @override
  List<Object?> get props => [email, isResend];
}

class AuthUpdatePhoneOtpSentState extends AuthState {
  final String phone;
  final String phoneCode;
  final String countryCode;

  const AuthUpdatePhoneOtpSentState(
    this.phone,
    this.phoneCode,
    this.countryCode,
  );

  @override
  List<Object?> get props => [phone, phoneCode, countryCode];
}

class AuthUpdatePhoneSuccessState extends AuthState {
  const AuthUpdatePhoneSuccessState();
}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthVerifySignupEmailSuccessState extends AuthState {
  const AuthVerifySignupEmailSuccessState();
}

class AuthVerifyPasswordRecoveryOtpSuccessState extends AuthState {
  const AuthVerifyPasswordRecoveryOtpSuccessState();
}

class AuthResendSignupEmailSuccessState extends AuthState {
  const AuthResendSignupEmailSuccessState();
}
