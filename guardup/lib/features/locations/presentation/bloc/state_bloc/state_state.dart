import 'package:equatable/equatable.dart';
import '../../../domain/entities/location_state_entity.dart';

abstract class StateState extends Equatable {
  const StateState();

  @override
  List<Object?> get props => [];
}

class StateInitial extends StateState {
  const StateInitial();
}

class StateLoading extends StateState {
  const StateLoading();
}

class StateError extends StateState {
  final String message;
  const StateError(this.message);

  @override
  List<Object?> get props => [message];
}

class StateLoaded extends StateState {
  final List<LocationStateEntity> states;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;

  const StateLoaded({
    this.states = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery,
  });

  StateLoaded copyWith({
    List<LocationStateEntity>? states,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
  }) {
    return StateLoaded(
      states: states ?? this.states,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [states, hasReachedMax, currentPage, searchQuery];
}
