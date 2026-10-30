import 'package:equatable/equatable.dart';

import '../../../domain/entities/location_country_entity.dart';

abstract class CountryState extends Equatable {
  const CountryState();

  @override
  List<Object?> get props => [];
}

class CountryInitial extends CountryState {
  const CountryInitial();
}

class CountryLoading extends CountryState {
  const CountryLoading();
}

class CountryError extends CountryState {
  final String message;
  const CountryError(this.message);

  @override
  List<Object?> get props => [message];
}

class CountryLoaded extends CountryState {
  final List<LocationCountryEntity> countries;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;
  final bool isFetchingMore;
  final int limit;

  const CountryLoaded({
    this.countries = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery,
    this.isFetchingMore = false,
    this.limit = 20,
  });

  CountryLoaded copyWith({
    List<LocationCountryEntity>? countries,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    bool? isFetchingMore,
    int? limit,
  }) {
    return CountryLoaded(
      countries: countries ?? this.countries,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    countries,
    hasReachedMax,
    currentPage,
    searchQuery,
    isFetchingMore,
    limit,
  ];
}
