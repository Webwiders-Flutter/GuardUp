import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/model/company.model.dart';
import '../../data/repositories/company.repository.dart';

class CompaniesState extends Equatable {
  final PaginationState<CompanyModel> pagination;
  final String search;
  final UserStatus? statusFilter;

  const CompaniesState({
    this.pagination = const PaginationState<CompanyModel>(),
    this.search = '',
    this.statusFilter,
  });

  CompaniesState copyWith({
    PaginationState<CompanyModel>? pagination,
    String? search,
    UserStatus? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return CompaniesState(
      pagination: pagination ?? this.pagination,
      search: search ?? this.search,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }

  @override
  List<Object?> get props => [pagination, search, statusFilter];
}

class CompaniesCubit extends Cubit<CompaniesState> {
  final CompanyRepository _repository;
  int _requestId = 0;

  CompaniesCubit(this._repository) : super(const CompaniesState());

  /// Loads the first page.
  Future<void> refresh({
    String? search,
    UserStatus? status = UserStatus.active,
    bool updateStatus = false,
    int pageSize = 10,
  }) async {
    final requestId = ++_requestId;
    final term = search ?? state.search;
    final stat = updateStatus ? status : (state.statusFilter ?? status);

    emit(
      state.copyWith(
        search: term,
        statusFilter: stat,
        clearStatusFilter: updateStatus && status == null,
        pagination: state.pagination.copyWith(
          pageSize: pageSize,
          status: const ApiState.loading(),
          loadMoreStatus: const ApiState.initial(),
        ),
      ),
    );

    try {
      final result = await _repository.getPaginated(
        page: 1,
        pageSize: pageSize,
        search: term,
        status: stat,
      );

      if (isClosed || requestId != _requestId) return;

      emit(
        state.copyWith(
          pagination: PaginationState<CompanyModel>(
            items: result.data,
            total: result.total,
            page: 1,
            pageSize: pageSize,
            status: const ApiState.success(null),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e(
        'CompaniesCubit.refresh',
        tag: 'CompaniesCubit',
        error: e,
        stackTrace: st,
      );
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
    if (state.pagination.isLastPage ||
        state.pagination.isLoading ||
        state.pagination.isLoadingMore) {
      return;
    }

    final requestId = ++_requestId;
    final nextPage = state.pagination.page + 1;
    final pageSize = state.pagination.pageSize;

    emit(
      state.copyWith(
        pagination: state.pagination.copyWith(
          loadMoreStatus: const ApiState.loading(),
        ),
      ),
    );

    try {
      final result = await _repository.getPaginated(
        page: nextPage,
        pageSize: pageSize,
        search: state.search,
        status: state.statusFilter,
      );

      if (isClosed || requestId != _requestId) return;

      final combined = [...state.pagination.items, ...result.data];
      emit(
        state.copyWith(
          pagination: state.pagination.copyWith(
            items: combined,
            total: result.total,
            page: nextPage,
            loadMoreStatus: const ApiState.success(null),
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.e(
        'CompaniesCubit.loadMore',
        tag: 'CompaniesCubit',
        error: e,
        stackTrace: st,
      );
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

  static String _message(Object error) {
    if (error is ApiException) return error.message;
    return 'Failed to load security companies';
  }
}
