import 'package:equatable/equatable.dart';

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

  const AuthProfileChanged(this.profile);

  @override
  List<Object?> get props => [profile];
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

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Dispatched when a new user registers with email, password, and optional name.
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String? name;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

/// Dispatched when the user updates profile details.
class AuthUpdateProfileRequested extends AuthEvent {
  final String? name;
  final String? profileImageUrl;

  const AuthUpdateProfileRequested({
    this.name,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [name, profileImageUrl];
}

/// Dispatched when the user logs out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
