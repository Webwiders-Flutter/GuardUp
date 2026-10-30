import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/utils/app_logs.dart';

import '../../../domain/usecases/get_cities_usecase.dart';
import 'city_event.dart';
import 'city_state.dart';

export 'city_event.dart';
export 'city_state.dart';

class CityBloc extends Bloc<CityEvent, CityState> {
  final GetCitiesUseCase getCitiesUseCase;

  CityBloc({required this.getCitiesUseCase}) : super(const CityInitial()) {
    on<FetchCities>(_onFetchCities);
    on<LoadMoreCities>(_onLoadMoreCities);
  }

  CityLoaded _getLoadedState() {
    if (state is CityLoaded) {
      return state as CityLoaded;
    }
    return const CityLoaded();
  }

  Future<void> _onFetchCities(
    FetchCities event,
    Emitter<CityState> emit,
  ) async {
    final loadedState = _getLoadedState();
    final query = event.searchQuery ?? loadedState.searchQuery;

    if (event.isRefresh || state is! CityLoaded) {
      emit(const CityLoading());
    } else {
      emit(loadedState.copyWith(searchQuery: query));
    }

    final result = await getCitiesUseCase(
      stateId: event.stateId,
      page: event.isRefresh ? 1 : _getLoadedState().currentPage,
      limit: event.limit,
      searchQuery: query,
    );

    result.fold((failure) => emit(CityError(failure.message)), (cities) {
      final isMax = cities.length < 20;
      final newCities = event.isRefresh
          ? cities
          : [..._getLoadedState().cities, ...cities];
      AppLogs.info('Loaded ${newCities.length} cities');
      emit(
        CityLoaded(
          cities: newCities,
          hasReachedMax: isMax,
          currentPage: event.isRefresh ? 1 : _getLoadedState().currentPage,
          searchQuery: query,
        ),
      );
    });
  }

  Future<void> _onLoadMoreCities(
    LoadMoreCities event,
    Emitter<CityState> emit,
  ) async {
    if (state is! CityLoaded) return;
    final loadedState = state as CityLoaded;
    if (loadedState.hasReachedMax) return;

    final nextPage = loadedState.currentPage + 1;
    final query = event.searchQuery ?? loadedState.searchQuery;

    final result = await getCitiesUseCase(
      stateId: event.stateId,
      page: nextPage,
      limit: 20,
      searchQuery: query,
    );

    result.fold((failure) => emit(CityError(failure.message)), (cities) {
      final isMax = cities.length < 20;
      final newCities = [...loadedState.cities, ...cities];
      AppLogs.info('Loaded ${newCities.length} cities');
      emit(
        loadedState.copyWith(
          cities: newCities,
          hasReachedMax: isMax,
          currentPage: nextPage,
        ),
      );
    });
  }
}
