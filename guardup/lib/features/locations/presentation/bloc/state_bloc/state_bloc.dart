import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/utils/app_logs.dart';

import '../../../domain/usecases/get_states_usecase.dart';
import 'state_event.dart';
import 'state_state.dart';

export 'state_event.dart';
export 'state_state.dart';

class StateBloc extends Bloc<StateEvent, StateState> {
  final GetStatesUseCase getStatesUseCase;

  StateBloc({required this.getStatesUseCase}) : super(const StateInitial()) {
    on<FetchStates>(_onFetchStates);
    on<LoadMoreStates>(_onLoadMoreStates);
  }

  StateLoaded _getLoadedState() {
    if (state is StateLoaded) {
      return state as StateLoaded;
    }
    return const StateLoaded();
  }

  Future<void> _onFetchStates(
    FetchStates event,
    Emitter<StateState> emit,
  ) async {
    final loadedState = _getLoadedState();
    final query = event.searchQuery ?? loadedState.searchQuery;

    if (event.isRefresh || state is! StateLoaded) {
      emit(const StateLoading());
    } else {
      emit(loadedState.copyWith(searchQuery: query));
    }

    final result = await getStatesUseCase(
      countryId: event.countryId,
      page: event.isRefresh ? 1 : _getLoadedState().currentPage,
      limit: event.limit,
      searchQuery: query,
    );

    result.fold((failure) => emit(StateError(failure.message)), (states) {
      final isMax = states.length < 20;
      final newStates = event.isRefresh
          ? states
          : [..._getLoadedState().states, ...states];
      AppLogs.info('Loaded ${newStates.length} states');
      emit(
        StateLoaded(
          states: newStates,
          hasReachedMax: isMax,
          currentPage: event.isRefresh ? 1 : _getLoadedState().currentPage,
          searchQuery: query,
        ),
      );
    });
  }

  Future<void> _onLoadMoreStates(
    LoadMoreStates event,
    Emitter<StateState> emit,
  ) async {
    if (state is! StateLoaded) return;
    final loadedState = state as StateLoaded;
    if (loadedState.hasReachedMax) return;

    final nextPage = loadedState.currentPage + 1;
    final query = event.searchQuery ?? loadedState.searchQuery;

    final result = await getStatesUseCase(
      countryId: event.countryId,
      page: nextPage,
      limit: 20,
      searchQuery: query,
    );

    result.fold((failure) => emit(StateError(failure.message)), (states) {
      final isMax = states.length < 20;
      final newStates = [...loadedState.states, ...states];
      AppLogs.info('Loaded ${newStates.length} states');
      emit(
        loadedState.copyWith(
          states: newStates,
          hasReachedMax: isMax,
          currentPage: nextPage,
        ),
      );
    });
  }
}
