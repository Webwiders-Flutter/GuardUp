import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';

import '../entities/location_country_entity.dart';
import '../repositories/location_repository.dart';

class GetLocationCountriesUseCase {
  final LocationRepository repository;

  GetLocationCountriesUseCase(this.repository);

  Future<Either<Failure, List<LocationCountryEntity>>> call({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? showInTravel,
    bool? showInVideoHub,
  }) async {
    try {
      final countries = await repository.getCountries(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        showInTravel: showInTravel,
        showInVideoHub: showInVideoHub,
      );
      return Right(countries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
