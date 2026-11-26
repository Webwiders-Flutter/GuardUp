import '/shared/bloc/pagination/paginated_bloc.dart';
import '../data/models/service.model.dart';
import '../data/repositories/services.repository.dart';

typedef ServicesState = PaginatedState<ServiceModel, bool>;

/// Paginated bloc for listing active security services with search.
class ServicesBloc extends PaginatedBloc<ServiceModel, bool> {
  ServicesBloc(
    this._repository, {
    super.initialFilters = true,
    super.pageSize,
  });

  final ServicesRepository _repository;

  @override
  Future<({List<ServiceModel> data, int total})> fetchPage({
    required int page,
    required int pageSize,
    required bool filters,
    required String search,
  }) {
    return _repository.getPaginated(
      page: page,
      pageSize: pageSize,
      isActive: filters,
      search: search.isEmpty ? null : search,
    );
  }
}
