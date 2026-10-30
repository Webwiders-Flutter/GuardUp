import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';

import '../entities/location_state_entity.dart';
import '../repositories/location_repository.dart';

class GetStatesUseCase {
  final LocationRepository repository;

  GetStatesUseCase(this.repository);

  Future<Either<Failure, List<LocationStateEntity>>> call({
    required int countryId,
    int page = 1,
    int limit = 20,
    String? searchQuery,
  }) async {
    try {
      final states = await repository.getStates(
        countryId: countryId,
        page: page,
        limit: limit,
        searchQuery: searchQuery,
      );
      return Right(states);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
