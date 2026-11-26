import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/model/user_bank_account.model.dart';

enum BankAccountAction { none, add, update, delete, setPrimary }

class BankAccountsState extends Equatable {
  const BankAccountsState({
    this.accounts = const [],
    this.loadStatus = const ApiState.initial(),
    this.actionStatus = const ApiState.initial(),
    this.lastAction = BankAccountAction.none,
  });

  final List<UserBankAccountModel> accounts;
  final ApiState<void> loadStatus;
  final ApiState<void> actionStatus;
  final BankAccountAction lastAction;

  BankAccountsState copyWith({
    List<UserBankAccountModel>? accounts,
    ApiState<void>? loadStatus,
    ApiState<void>? actionStatus,
    BankAccountAction? lastAction,
  }) {
    return BankAccountsState(
      accounts: accounts ?? this.accounts,
      loadStatus: loadStatus ?? this.loadStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      lastAction: lastAction ?? this.lastAction,
    );
  }

  @override
  List<Object?> get props => [accounts, loadStatus, actionStatus, lastAction];
}
