import 'package:equatable/equatable.dart';
import '../../../domain/entities/location_city_entity.dart';

abstract class CityState extends Equatable {
  const CityState();

  @override
  List<Object?> get props => [];
}

class CityInitial extends CityState {
  const CityInitial();
}

class CityLoading extends CityState {
  const CityLoading();
}

class CityError extends CityState {
  final String message;
  const CityError(this.message);

  @override
  List<Object?> get props => [message];
}

class CityLoaded extends CityState {
  final List<LocationCityEntity> cities;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;

  const CityLoaded({
    this.cities = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery,
  });

  CityLoaded copyWith({
    List<LocationCityEntity>? cities,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
  }) {
    return CityLoaded(
      cities: cities ?? this.cities,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [cities, hasReachedMax, currentPage, searchQuery];
}
