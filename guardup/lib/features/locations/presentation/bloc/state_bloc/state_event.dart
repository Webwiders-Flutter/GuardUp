import 'package:equatable/equatable.dart';

abstract class StateEvent extends Equatable {
  const StateEvent();

  @override
  List<Object?> get props => [];
}

class FetchStates extends StateEvent {
  final int countryId;
  final int limit;
  final bool isRefresh;
  final String? searchQuery;

  const FetchStates({
    required this.countryId,
    this.limit = 20,
    this.isRefresh = false,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [countryId, limit, isRefresh, searchQuery];
}

class LoadMoreStates extends StateEvent {
  final int countryId;
  final String? searchQuery;

  const LoadMoreStates({required this.countryId, this.searchQuery});

  @override
  List<Object?> get props => [countryId, searchQuery];
}
