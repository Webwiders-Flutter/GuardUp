import 'package:equatable/equatable.dart';

import '../../data/model/bank_account_request.model.dart';

abstract class BankAccountsEvent extends Equatable {
  const BankAccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads all saved bank accounts for the current user.
final class BankAccountsStarted extends BankAccountsEvent {
  const BankAccountsStarted();
}

/// Adds a new bank account.
final class BankAccountAdded extends BankAccountsEvent {
  const BankAccountAdded(this.request);

  final BankAccountRequest request;

  @override
  List<Object?> get props => [request];
}

/// Updates an existing bank account by [id].
final class BankAccountUpdated extends BankAccountsEvent {
  const BankAccountUpdated(this.id, this.request);

  final String id;
  final BankAccountRequest request;

  @override
  List<Object?> get props => [id, request];
}

/// Deletes a bank account by [id].
final class BankAccountDeleted extends BankAccountsEvent {
  const BankAccountDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Marks a bank account [id] as the primary payout account.
final class BankAccountPrimarySet extends BankAccountsEvent {
  const BankAccountPrimarySet(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

