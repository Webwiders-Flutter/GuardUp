import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import '../../data/enum/bodyguard_availability_status.enum.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/repositories/bodyguard.repository.dart';

class BodyguardsState extends Equatable {
  final PaginationState<BodyGuardModel> pagination;
  final String search;
  final String? companyId;
  final UserStatus? statusFilter;
  final BodyguardAvailabilityStatus? availabilityStatus;

  const BodyguardsState({
    this.pagination = const PaginationState<BodyGuardModel>(),
    this.search = '',
    this.companyId,
    this.statusFilter,
    this.availabilityStatus,
  });

  BodyguardsState copyWith({
    PaginationState<BodyGuardModel>? pagination,
    String? search,
    String? companyId,
    bool clearCompanyId = false,
    UserStatus? statusFilter,
    bool clearStatusFilter = false,
    BodyguardAvailabilityStatus? availabilityStatus,
    bool clearAvailabilityStatus = false,
  }) {
    return BodyguardsState(
      pagination: pagination ?? this.pagination,
      search: search ?? this.search,
      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      availabilityStatus:
          clearAvailabilityStatus
              ? null
              : (availabilityStatus ?? this.availabilityStatus),
    );
  }

  @override
  List<Object?> get props => [
    pagination,
    search,
    companyId,
    statusFilter,
    availabilityStatus,
  ];
}

/// Cubit for paginated bodyguard queries (all active guards, company-scoped guards,
/// availability-filtered guards).
class BodyguardsCubit extends Cubit<BodyguardsState> {
  final BodyguardRepository _repository;
  int _requestId = 0;

  BodyguardsCubit(this._repository) : super(const BodyguardsState());

  /// Loads the first page.
  Future<void> refresh({
    String? search,
    String? companyId,
    bool updateCompanyId = false,
    UserStatus? status,
    bool updateStatus = false,
    BodyguardAvailabilityStatus? availabilityStatus,
    bool updateAvailability = false,
    int? customPageSize,
  }) async {
    final term = search ?? state.search;
    final compId = updateCompanyId ? companyId : state.companyId;
    final stat = updateStatus ? status : state.statusFilter;
    final avail =
        updateAvailability ? availabilityStatus : state.availabilityStatus;
    final requestId = ++_requestId;
    final pageSize = customPageSize ?? state.pagination.pageSize;

    emit(
      state.copyWith(
        search: term,
        companyId: compId,
        clearCompanyId: updateCompanyId && companyId == null,
        statusFilter: stat,
        clearStatusFilter: updateStatus && status == null,
        availabilityStatus: avail,
        clearAvailabilityStatus: updateAvailability && availabilityStatus == null,
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
        companyId: compId,
        status: stat,
        availabilityStatus: avail,
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
      AppLogger.e('BodyguardsCubit.refresh', tag: 'BodyguardsCubit', error: e, stackTrace: st);
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
      final result = await _repository.getPaginated(
        page: nextPage,
        pageSize: current.pageSize,
        search: state.search,
        companyId: state.companyId,
        status: state.statusFilter,
        availabilityStatus: state.availabilityStatus,
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
      AppLogger.e('BodyguardsCubit.loadMore', tag: 'BodyguardsCubit', error: e, stackTrace: st);
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

  String _message(Object e) =>
      e is ApiException ? e.message : 'Something went wrong. Please try again.';
}
