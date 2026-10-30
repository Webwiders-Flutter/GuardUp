import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';

import '../entities/location_city_entity.dart';
import '../repositories/location_repository.dart';

class GetCitiesUseCase {
  final LocationRepository repository;

  GetCitiesUseCase(this.repository);

  Future<Either<Failure, List<LocationCityEntity>>> call({
    required int stateId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
  }) async {
    try {
      final cities = await repository.getCities(
        stateId: stateId,
        page: page,
        limit: limit,
        searchQuery: searchQuery,
      );
      return Right(cities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
