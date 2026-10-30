import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';

import '../entities/location_country_entity.dart';
import '../repositories/location_repository.dart';

class GetLocationCountriesByIdsUseCase {
  final LocationRepository repository;

  GetLocationCountriesByIdsUseCase(this.repository);

  Future<Either<Failure, List<LocationCountryEntity>>> call(
    List<int> ids,
  ) async {
    try {
      final countries = await repository.getCountriesByIds(ids);
      return Right(countries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
