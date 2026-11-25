import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/repositories/bodyguard.repository.dart';

class CompanyBodyguardsState extends Equatable {
  final PaginationState<BodyGuardModel> pagination;
  final String search;
  final UserStatus? statusFilter;

  /// Set when an action (e.g. delete) failed; cleared on the next action.
  final String? actionError;

  const CompanyBodyguardsState({
    this.pagination = const PaginationState<BodyGuardModel>(),
    this.search = '',
    this.statusFilter,
    this.actionError,
  });

  CompanyBodyguardsState copyWith({
    PaginationState<BodyGuardModel>? pagination,
    String? search,
    UserStatus? statusFilter,
    bool clearStatusFilter = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return CompanyBodyguardsState(
      pagination: pagination ?? this.pagination,
      search: search ?? this.search,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [pagination, search, statusFilter, actionError];
}

/// Loads and manages the bodyguards of the signed-in company.
class CompanyBodyguardsCubit extends Cubit<CompanyBodyguardsState> {
  final BodyguardRepository _repository;

  /// Guards against an older request overwriting a newer one (e.g. typing).
  int _requestId = 0;

  CompanyBodyguardsCubit(this._repository)
    : super(const CompanyBodyguardsState());

  /// Loads page 1. [search] or [status] replaces the current filter when given.
  Future<void> refresh({
    String? search,
    UserStatus? status,
    bool updateStatus = false,
  }) async {
    final term = search ?? state.search;
    final statusFilter =
        updateStatus ? status : state.statusFilter;
    final requestId = ++_requestId;
    final pageSize = state.pagination.pageSize;

    emit(
      state.copyWith(
        search: term,
        statusFilter: statusFilter,
        clearStatusFilter: updateStatus && status == null,
        clearActionError: true,
        pagination: state.pagination.copyWith(
          status: const ApiState.loading(),
          loadMoreStatus: const ApiState.initial(),
        ),
      ),
    );

    try {
      final statuses = statusFilter == UserStatus.pendingApproval
          ? [UserStatus.pendingApproval, UserStatus.incomplete]
          : (statusFilter != null ? [statusFilter] : null);

      final result = await _repository.getCompanyBodyguards(
        page: 1,
        pageSize: pageSize,
        search: term,
        statuses: statuses,
      );
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          pagination: PaginationState<BodyGuardModel>(
            items: result.data,
            total: result.total,
            page: 1,
            pageSize: pageSize,
            status: const ApiState.success(null),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e('CompanyBodyguardsCubit.refresh', tag: 'CompanyBodyguards', error: e, stackTrace: st);
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          pagination: state.pagination.copyWith(
            status: ApiState.failure(_message(e)),
          ),
        ),
      );
    }
  }

  /// Appends the next page.
  Future<void> loadMore() async {
    final current = state.pagination;
    if (current.isLoading || current.isLoadingMore || current.isLastPage) {
      return;
    }
    final requestId = _requestId;
    final nextPage = current.page + 1;

    emit(
      state.copyWith(
        pagination: current.copyWith(loadMoreStatus: const ApiState.loading()),
      ),
    );

    try {
      final statuses = state.statusFilter == UserStatus.pendingApproval
          ? [UserStatus.pendingApproval, UserStatus.incomplete]
          : (state.statusFilter != null ? [state.statusFilter!] : null);

      final result = await _repository.getCompanyBodyguards(
        page: nextPage,
        pageSize: current.pageSize,
        search: state.search,
        statuses: statuses,
      );
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          pagination: state.pagination.copyWith(
            items: [...state.pagination.items, ...result.data],
            total: result.total,
            page: nextPage,
            loadMoreStatus: const ApiState.success(null),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e('CompanyBodyguardsCubit.loadMore', tag: 'CompanyBodyguards', error: e, stackTrace: st);
      if (isClosed || requestId != _requestId) return;
      emit(
        state.copyWith(
          pagination: state.pagination.copyWith(
            loadMoreStatus: ApiState.failure(_message(e)),
          ),
        ),
      );
    }
  }

  /// Deletes a bodyguard and removes it from the list. Returns whether it
  /// was deleted; on failure [CompanyBodyguardsState.actionError] is set.
  Future<bool> delete(BodyGuardModel bodyguard) async {
    emit(state.copyWith(clearActionError: true));
    try {
      await _repository.deleteCompanyBodyguard(bodyguard.id);
      if (isClosed) return true;
      final items = List<BodyGuardModel>.from(state.pagination.items)
        ..removeWhere((g) => g.id == bodyguard.id);
      final total = state.pagination.total > 0 ? state.pagination.total - 1 : 0;
      emit(
        state.copyWith(
          pagination: state.pagination.copyWith(items: items, total: total),
        ),
      );
      return true;
    } catch (e, st) {
      AppLogger.e('CompanyBodyguardsCubit.delete', tag: 'CompanyBodyguards', error: e, stackTrace: st);
      if (!isClosed) emit(state.copyWith(actionError: _message(e)));
      return false;
    }
  }

  String _message(Object e) => e is ApiException
      ? e.message
      : 'Something went wrong. Please try again.';
}
