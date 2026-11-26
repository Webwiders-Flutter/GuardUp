import 'package:equatable/equatable.dart';

import '../data/enum/user_role.enum.dart';

/// Events handled by session-only [AuthBloc].
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Starts watching auth session state changes and initial session bootstrap.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Re-fetches the current user's full profile and updates session state.
class AuthProfileRefreshRequested extends AuthEvent {
  const AuthProfileRefreshRequested();
}

/// Stores the role chosen before sign-up (`SelectRoleScreen`).
class AuthRoleSelected extends AuthEvent {
  const AuthRoleSelected(this.role);

  final UserRole role;

  @override
  List<Object?> get props => [role];
}

/// Signs out the current session and resets state to unauthenticated.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
