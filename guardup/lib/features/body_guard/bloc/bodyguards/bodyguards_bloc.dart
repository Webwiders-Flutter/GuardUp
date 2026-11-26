import 'package:bloc_concurrency/bloc_concurrency.dart';

import '/features/auth/data/enum/user_status.enum.dart';
import '/shared/bloc/pagination/paginated_bloc.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/model/bodyguard_filters.model.dart';
import '../../data/repositories/bodyguard.repository.dart';

typedef BodyguardsState = PaginatedState<BodyGuardModel, BodyguardFilters>;

/// Dispatched when filters for bodyguard listings change.
final class BodyguardsFiltersChanged extends PaginationEvent {
  const BodyguardsFiltersChanged(this.filters);

  final BodyguardFilters filters;

  @override
  List<Object?> get props => [filters];
}

/// Paginated bloc for browsing and searching bodyguards.
class BodyguardsBloc extends PaginatedBloc<BodyGuardModel, BodyguardFilters> {
  BodyguardsBloc(
    this._repository, {
    super.initialFilters = const BodyguardFilters(
      statuses: [UserStatus.active],
    ),
    super.pageSize,
  }) {
    on<BodyguardsFiltersChanged>(
      (event, emit) => applyFilters(event.filters, emit),
      transformer: restartable(),
    );
  }

  final BodyguardRepository _repository;

  @override
  Future<({List<BodyGuardModel> data, int total})> fetchPage({
    required int page,
    required int pageSize,
    required BodyguardFilters filters,
    required String search,
  }) {
    return _repository.getPaginated(
      page: page,
      pageSize: pageSize,
      filters: filters,
      search: search.isEmpty ? null : search,
    );
  }
}

