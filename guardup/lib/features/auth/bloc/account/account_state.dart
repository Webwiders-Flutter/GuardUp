import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/model/user.model.dart';

/// Action kinds tracked in [AccountState.status].
enum AccountAction {
  profileSaved,
  profileRefreshed,
  passwordChanged,
  accountDeleted,
}

/// Immutable state for [AccountBloc].
final class AccountState extends Equatable {
  const AccountState({
    this.status = const ApiState.initial(),
    this.updatedUser,
  });

  final ApiState<AccountAction> status;
  final UserModel? updatedUser;

  AccountState copyWith({
    ApiState<AccountAction>? status,
    UserModel? updatedUser,
  }) {
    return AccountState(
      status: status ?? this.status,
      updatedUser: updatedUser ?? this.updatedUser,
    );
  }

  @override
  List<Object?> get props => [status, updatedUser];
}
