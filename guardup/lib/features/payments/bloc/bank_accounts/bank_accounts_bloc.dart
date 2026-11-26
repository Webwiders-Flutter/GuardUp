import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/model/bank_account_request.model.dart';
import '../../data/repositories/bank_account.repository.dart';
import 'bank_accounts_event.dart';
import 'bank_accounts_state.dart';

export 'bank_accounts_event.dart';
export 'bank_accounts_state.dart';

/// Manages the user's saved bank accounts (`public.user_bank_accounts`).
class BankAccountsBloc extends Bloc<BankAccountsEvent, BankAccountsState> {
  BankAccountsBloc(
    this._repository, {
    required this.getUserId,
  }) : super(const BankAccountsState()) {
    on<BankAccountsStarted>(_onStarted, transformer: restartable());
    on<BankAccountAdded>(_onAdded);
    on<BankAccountUpdated>(_onUpdated);
    on<BankAccountDeleted>(_onDeleted);
    on<BankAccountPrimarySet>(_onPrimarySet);
  }

  final BankAccountRepository _repository;
  final String? Function() getUserId;

  Future<void> _onStarted(
    BankAccountsStarted event,
    Emitter<BankAccountsState> emit,
  ) async {
    final userId = getUserId();
    if (userId == null || userId.isEmpty) {
      emit(
        state.copyWith(
          accounts: const [],
          loadStatus: const ApiState.success(null),
        ),
      );
      return;
    }

    emit(state.copyWith(loadStatus: const ApiState.loading()));

    try {
      final accounts = await asyncHandler(() => _repository.getAll(userId));
      emit(
        state.copyWith(
          accounts: accounts,
          loadStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          loadStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  Future<void> _onAdded(
    BankAccountAdded event,
    Emitter<BankAccountsState> emit,
  ) async {
    final userId = getUserId();
    if (userId == null || userId.isEmpty) {
      emit(
        state.copyWith(
          lastAction: BankAccountAction.add,
          actionStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        lastAction: BankAccountAction.add,
        actionStatus: const ApiState.loading(),
      ),
    );

    final req = event.request;
    final effectiveRequest = BankAccountRequest(
      accountNumber: req.accountNumber,
      accountHolder: req.accountHolder,
      bankName: req.bankName,
      branch: req.branch,
      ifscCode: req.ifscCode,
      branchAddress: req.branchAddress,
      isPrimary: state.accounts.isEmpty || req.isPrimary,
    );

    try {
      final created = await asyncHandler(
        () => _repository.add(userId, effectiveRequest),
      );
      emit(
        state.copyWith(
          accounts: [created, ...state.accounts],
          lastAction: BankAccountAction.add,
          actionStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          lastAction: BankAccountAction.add,
          actionStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  Future<void> _onUpdated(
    BankAccountUpdated event,
    Emitter<BankAccountsState> emit,
  ) async {
    emit(
      state.copyWith(
        lastAction: BankAccountAction.update,
        actionStatus: const ApiState.loading(),
      ),
    );

    try {
      final updated = await asyncHandler(
        () => _repository.update(event.id, event.request),
      );
      final nextAccounts = state.accounts
          .map((a) => a.id == updated.id ? updated : a)
          .toList();
      emit(
        state.copyWith(
          accounts: nextAccounts,
          lastAction: BankAccountAction.update,
          actionStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          lastAction: BankAccountAction.update,
          actionStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  Future<void> _onDeleted(
    BankAccountDeleted event,
    Emitter<BankAccountsState> emit,
  ) async {
    final previous = state.accounts;
    final filtered = previous.where((a) => a.id != event.id).toList();
    emit(
      state.copyWith(
        accounts: filtered,
        lastAction: BankAccountAction.delete,
        actionStatus: const ApiState.loading(),
      ),
    );

    try {
      await asyncHandler(() => _repository.delete(event.id));
      emit(
        state.copyWith(
          lastAction: BankAccountAction.delete,
          actionStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          accounts: previous,
          lastAction: BankAccountAction.delete,
          actionStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  Future<void> _onPrimarySet(
    BankAccountPrimarySet event,
    Emitter<BankAccountsState> emit,
  ) async {
    final userId = getUserId();
    if (userId == null || userId.isEmpty) return;

    final previous = state.accounts;
    final updated = [
      for (final account in previous)
        account.copyWith(isPrimary: account.id == event.id),
    ]..sort((a, b) => (b.isPrimary ? 1 : 0).compareTo(a.isPrimary ? 1 : 0));

    emit(
      state.copyWith(
        accounts: updated,
        lastAction: BankAccountAction.setPrimary,
        actionStatus: const ApiState.loading(),
      ),
    );

    try {
      await asyncHandler(() => _repository.setPrimary(userId, event.id));
      emit(
        state.copyWith(
          lastAction: BankAccountAction.setPrimary,
          actionStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          accounts: previous,
          lastAction: BankAccountAction.setPrimary,
          actionStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }
}

