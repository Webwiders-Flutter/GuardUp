import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../data/enum/user_role.enum.dart';
import '../data/model/user.model.dart';

/// The single source of truth for global session authentication.
enum AuthSessionStatus { unknown, authenticated, unauthenticated }

/// Represents the authentication state of the application.
///
/// Combines the single-source-of-truth [sessionStatus] with the reusable
/// [operationState] for async actions (login, register, profile updates).
class AuthState extends Equatable {
  final AuthSessionStatus sessionStatus;
  final ApiState<UserModel> operationState;

  const AuthState({
    this.sessionStatus = AuthSessionStatus.unknown,
    this.operationState = const ApiState.initial(),
  });

  const AuthState.unknown()
    : this(
        sessionStatus: AuthSessionStatus.unknown,
        operationState: const ApiState.initial(),
      );

  const AuthState.unauthenticated({
    ApiState<UserModel> operationState = const ApiState.initial(),
  }) : this(
         sessionStatus: AuthSessionStatus.unauthenticated,
         operationState: operationState,
       );

  AuthState.authenticated(UserModel user, {ApiState<UserModel>? operationState})
    : this(
        sessionStatus: AuthSessionStatus.authenticated,
        operationState: operationState ?? ApiSuccess(user),
      );

  bool get isAuthenticated => sessionStatus == AuthSessionStatus.authenticated;
  bool get isUnauthenticated =>
      sessionStatus == AuthSessionStatus.unauthenticated;
  bool get isUnknown => sessionStatus == AuthSessionStatus.unknown;

  UserModel? get user => operationState.dataOrNull;
  UserRole get sessionRole => user?.role ?? .company;
  bool get isLoading => operationState.isLoading;
  bool get hasError => operationState.isFailure;
  String? get errorMessage => operationState.errorMessageOrNull;

  AuthState copyWith({
    AuthSessionStatus? sessionStatus,
    ApiState<UserModel>? operationState,
  }) {
    return AuthState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      operationState: operationState ?? this.operationState,
    );
  }

  @override
  List<Object?> get props => [sessionStatus, operationState];
}
