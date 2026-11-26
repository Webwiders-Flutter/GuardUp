import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/app_constants.dart';
import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/shared/widgets/pagination/pagination.state.dart';
import 'paginated_state.dart';
import 'pagination_event.dart';

export 'paginated_state.dart';
export 'pagination_event.dart';

/// Base Bloc for every paginated list (refresh, search, next page).
///
/// Subclasses implement [fetchPage] and, if they have filters, a typed
/// "filters changed" event whose handler calls [applyFilters].
///
/// Stale responses are dropped with a generation counter: every page-1 load
/// bumps it, and any response (page 1 or later) started under an older
/// generation is ignored.
abstract class PaginatedBloc<T, F>
    extends Bloc<PaginationEvent, PaginatedState<T, F>> {
  PaginatedBloc({
    required F initialFilters,
    int pageSize = AppConstants.paginationLimit,
  }) : super(PaginatedState<T, F>.initial(initialFilters, pageSize: pageSize)) {
    on<PaginationLoadRequested>(
      (_, emit) => load(emit),
      transformer: restartable(),
    );
    on<PaginationSearchChanged>(_onSearchChanged, transformer: restartable());
    on<PaginationNextPageRequested>(_onNextPage, transformer: droppable());
  }

  int _generation = 0;

  /// Loads one page from the repository.
  @protected
  Future<({List<T> data, int total})> fetchPage({
    required int page,
    required int pageSize,
    required F filters,
    required String search,
  });

  /// For subclasses: call from a typed "filters changed" handler.
  @protected
  Future<void> applyFilters(F filters, Emitter<PaginatedState<T, F>> emit) {
    emit(state.copyWith(filters: filters));
    return load(emit);
  }

  Future<void> _onSearchChanged(
    PaginationSearchChanged event,
    Emitter<PaginatedState<T, F>> emit,
  ) {
    emit(state.copyWith(search: event.query.trim()));
    return load(emit);
  }

  /// Reloads page 1 with the current filters and search.
  @protected
  Future<void> load(Emitter<PaginatedState<T, F>> emit) async {
    final generation = ++_generation;
    final pageSize = state.pagination.pageSize;
    emit(
      state.copyWith(
        pagination: state.pagination.copyWith(
          status: const ApiState.loading(),
          loadMoreStatus: const ApiState.initial(),
        ),
      ),
    );
    try {
      final result = await asyncHandler(
        () => fetchPage(
          page: 1,
          pageSize: pageSize,
          filters: state.filters,
          search: state.search,
        ),
      );
      if (generation != _generation) return;
      emit(
        state.copyWith(
          pagination: PaginationState<T>(
            items: result.data,
            total: result.total,
            page: 1,
            pageSize: pageSize,
            status: const ApiState.success(null),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          pagination: state.pagination.copyWith(
            status: ApiState.failure(e.message, error: e),
          ),
        ),
      );
    }
  }

  Future<void> _onNextPage(
    PaginationNextPageRequested event,
    Emitter<PaginatedState<T, F>> emit,
  ) async {
    final current = state.pagination;
    if (current.isLoading || current.isLoadingMore || current.isLastPage) {
      return;
    }
    final generation = _generation;
    final nextPage = current.page + 1;
    emit(
      state.copyWith(
        pagination: current.copyWith(loadMoreStatus: const ApiState.loading()),
      ),
    );
    try {
      final result = await asyncHandler(
        () => fetchPage(
          page: nextPage,
          pageSize: current.pageSize,
          filters: state.filters,
          search: state.search,
        ),
      );
      if (generation != _generation) return;
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
    } on ApiException catch (e) {
      if (generation != _generation) return;
      emit(
        state.copyWith(
          pagination: state.pagination.copyWith(
            loadMoreStatus: ApiState.failure(e.message, error: e),
          ),
        ),
      );
    }
  }

  /// Replaces every item matching [test] with `update(item)`.
  @protected
  PaginationState<T> replaceWhere(bool Function(T) test, T Function(T) update) {
    final items = [
      for (final item in state.pagination.items)
        test(item) ? update(item) : item,
    ];
    return state.pagination.copyWith(items: items);
  }

  /// Removes every item matching [test] and decrements `total` (min 0).
  @protected
  PaginationState<T> removeWhere(bool Function(T) test) {
    final before = state.pagination.items;
    final items = before.where((item) => !test(item)).toList();
    final removed = before.length - items.length;
    final total = state.pagination.total - removed;
    return state.pagination.copyWith(
      items: items,
      total: total < 0 ? 0 : total,
    );
  }
}
