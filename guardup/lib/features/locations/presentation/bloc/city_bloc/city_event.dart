import 'package:equatable/equatable.dart';

abstract class CityEvent extends Equatable {
  const CityEvent();

  @override
  List<Object?> get props => [];
}

class FetchCities extends CityEvent {
  final int stateId;
  final int limit;
  final bool isRefresh;
  final String? searchQuery;

  const FetchCities({
    required this.stateId,
    this.limit = 20,
    this.isRefresh = false,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [stateId, limit, isRefresh, searchQuery];
}

class LoadMoreCities extends CityEvent {
  final int stateId;
  final String? searchQuery;

  const LoadMoreCities({required this.stateId, this.searchQuery});

  @override
  List<Object?> get props => [stateId, searchQuery];
}
