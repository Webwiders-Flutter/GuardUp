import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/utils/app_logs.dart';

import '../../../domain/usecases/get_location_countries_usecase.dart';
import 'country_event.dart';
import 'country_state.dart';

export 'country_event.dart';
export 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final GetLocationCountriesUseCase getCountriesUseCase;

  CountryBloc({required this.getCountriesUseCase})
    : super(const CountryInitial()) {
    on<FetchCountries>(_onFetchCountries);
    on<LoadMoreCountries>(_onLoadMoreCountries);
  }

  CountryLoaded _getLoadedState() {
    if (state is CountryLoaded) {
      return state as CountryLoaded;
    }
    return const CountryLoaded();
  }

  Future<void> _onFetchCountries(
    FetchCountries event,
    Emitter<CountryState> emit,
  ) async {
    final loadedState = _getLoadedState();
    final query = event.searchQuery ?? loadedState.searchQuery;

    if (event.isRefresh || state is! CountryLoaded) {
      emit(const CountryLoading());
    } else {
      emit(loadedState.copyWith(searchQuery: query));
    }

    final result = await getCountriesUseCase(
      page: event.isRefresh ? 1 : _getLoadedState().currentPage,
      limit: event.limit,
      searchQuery: query,
      showInVideoHub: event.showInVideoHub,
    );

    result.fold((failure) => emit(CountryError(failure.message)), (countries) {
      final isMax = countries.length < event.limit;
      final newCountries = event.isRefresh
          ? countries
          : [..._getLoadedState().countries, ...countries];
      AppLogs.info('Loaded ${newCountries.length} countries');
      emit(
        CountryLoaded(
          countries: newCountries,
          hasReachedMax: isMax,
          currentPage: event.isRefresh ? 1 : _getLoadedState().currentPage,
          searchQuery: query,
          isFetchingMore: false,
          limit: event.limit,
        ),
      );
    });
  }

  Future<void> _onLoadMoreCountries(
    LoadMoreCountries event,
    Emitter<CountryState> emit,
  ) async {
    if (state is! CountryLoaded) return;
    final loadedState = state as CountryLoaded;
    if (loadedState.hasReachedMax || loadedState.isFetchingMore) return;

    emit(loadedState.copyWith(isFetchingMore: true));

    final nextPage = loadedState.currentPage + 1;
    final query = event.searchQuery ?? loadedState.searchQuery;
    final limit = loadedState.limit;

    final result = await getCountriesUseCase(
      page: nextPage,
      limit: limit,
      searchQuery: query,
      showInVideoHub: event.showInVideoHub,
    );

    result.fold(
      (failure) {
        emit(loadedState.copyWith(isFetchingMore: false));
        emit(CountryError(failure.message));
      },
      (countries) {
        final isMax = countries.length < limit;
        final newCountries = [...loadedState.countries, ...countries];
        AppLogs.info('Loaded ${newCountries.length} countries');
        emit(
          loadedState.copyWith(
            countries: newCountries,
            hasReachedMax: isMax,
            currentPage: nextPage,
            isFetchingMore: false,
          ),
        );
      },
    );
  }
}
