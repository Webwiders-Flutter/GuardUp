import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/enum/user_role.enum.dart';
import '../../data/enum/user_status.enum.dart';
import '../../data/model/user.model.dart';

/// Outcomes emitted in [AuthFormState.status] upon successful completion of an auth form action.
enum AuthFormResult {
  signedIn,
  signedUp,
  otpVerified,
  otpResent,
  resetCodeSent,
  passwordChanged,
  emailNotConfirmed,
}

/// Immutable state for screen-scoped [AuthFormBloc].
final class AuthFormState extends Equatable {
  const AuthFormState({
    this.status = const ApiState.initial(),
    this.email,
    this.authenticatedUser,
  });

  final ApiState<AuthFormResult> status;
  final String? email;
  final UserModel? authenticatedUser;

  /// Effective user status (customers default to active per parity rule 7.12).
  UserStatus get effectiveStatus {
    final user = authenticatedUser;
    if (user == null) return UserStatus.incomplete;
    return user.role == UserRole.customer ? UserStatus.active : user.status;
  }

  AuthFormState copyWith({
    ApiState<AuthFormResult>? status,
    String? email,
    UserModel? authenticatedUser,
    bool clearAuthenticatedUser = false,
  }) {
    return AuthFormState(
      status: status ?? this.status,
      email: email ?? this.email,
      authenticatedUser: clearAuthenticatedUser
          ? null
          : (authenticatedUser ?? this.authenticatedUser),
    );
  }

  @override
  List<Object?> get props => [status, email, authenticatedUser];
}
