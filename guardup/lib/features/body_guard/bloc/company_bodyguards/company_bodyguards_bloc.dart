import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/shared/bloc/pagination/paginated_bloc.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/model/bodyguard_filters.model.dart';
import '../../data/repositories/bodyguard.repository.dart';

typedef CompanyBodyguardsState =
    PaginatedState<BodyGuardModel, BodyguardFilters>;

/// Dispatched when the company selects a verification status filter tab.
final class CompanyBodyguardsStatusChanged extends PaginationEvent {
  const CompanyBodyguardsStatusChanged(this.status);

  final UserStatus? status;

  @override
  List<Object?> get props => [status];
}

/// Dispatched when the company deletes one of its managed bodyguards.
final class CompanyBodyguardDeleted extends PaginationEvent {
  const CompanyBodyguardDeleted(this.bodyguard);

  final BodyGuardModel bodyguard;

  @override
  List<Object?> get props => [bodyguard];
}

/// Paginated bloc for listing and managing a company's own bodyguards.
class CompanyBodyguardsBloc
    extends PaginatedBloc<BodyGuardModel, BodyguardFilters> {
  CompanyBodyguardsBloc(
    this._repository, {
    required this.companyUserId,
    super.pageSize,
  }) : super(initialFilters: const BodyguardFilters()) {
    on<CompanyBodyguardsStatusChanged>(
      _onStatusChanged,
      transformer: restartable(),
    );
    on<CompanyBodyguardDeleted>(_onDeleted);
  }

  final BodyguardRepository _repository;
  final String companyUserId;
  String? _cachedCompanyId;

  @override
  Future<({List<BodyGuardModel> data, int total})> fetchPage({
    required int page,
    required int pageSize,
    required BodyguardFilters filters,
    required String search,
  }) async {
    final companyId = _cachedCompanyId ??= await _repository.getMyCompanyId(
      companyUserId,
    );

    return _repository.getPaginated(
      page: page,
      pageSize: pageSize,
      filters: filters.copyWith(companyId: companyId),
      search: search.isEmpty ? null : search,
    );
  }

  Future<void> _onStatusChanged(
    CompanyBodyguardsStatusChanged event,
    Emitter<CompanyBodyguardsState> emit,
  ) {
    final statuses = switch (event.status) {
      null => null,
      UserStatus.pendingApproval => const [
        UserStatus.pendingApproval,
        UserStatus.incomplete,
      ],
      final status => [status],
    };

    return applyFilters(state.filters.copyWith(statuses: statuses), emit);
  }

  Future<void> _onDeleted(
    CompanyBodyguardDeleted event,
    Emitter<CompanyBodyguardsState> emit,
  ) async {
    final previous = state.pagination;
    emit(
      state.copyWith(
        pagination: removeWhere((g) => g.id == event.bodyguard.id),
        actionStatus: const ApiState.loading(),
      ),
    );

    try {
      await asyncHandler(() => _repository.delete(event.bodyguard.id));
      emit(state.copyWith(actionStatus: const ApiState.success(null)));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          pagination: previous,
          actionStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }
}
