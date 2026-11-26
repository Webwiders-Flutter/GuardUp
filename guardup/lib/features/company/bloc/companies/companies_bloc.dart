import 'package:bloc_concurrency/bloc_concurrency.dart';

import '/shared/bloc/pagination/paginated_bloc.dart';
import '../../data/model/company.model.dart';
import '../../data/model/company_filters.model.dart';
import '../../data/repositories/company.repository.dart';

typedef CompaniesState = PaginatedState<CompanyModel, CompanyFilters>;

/// Dispatched when customer or admin filters for companies change.
final class CompanyFiltersChanged extends PaginationEvent {
  const CompanyFiltersChanged(this.filters);

  final CompanyFilters filters;

  @override
  List<Object?> get props => [filters];
}

/// Paginated bloc for listing security companies.
class CompaniesBloc extends PaginatedBloc<CompanyModel, CompanyFilters> {
  CompaniesBloc(
    this._repository, {
    super.initialFilters = CompanyFilters.customerDefault,
    super.pageSize,
  }) {
    on<CompanyFiltersChanged>(
      (event, emit) => applyFilters(event.filters, emit),
      transformer: restartable(),
    );
  }

  final CompanyRepository _repository;

  @override
  Future<({List<CompanyModel> data, int total})> fetchPage({
    required int page,
    required int pageSize,
    required CompanyFilters filters,
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
