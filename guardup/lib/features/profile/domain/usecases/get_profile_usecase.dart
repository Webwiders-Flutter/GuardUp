import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';

import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String userId) async {
    try {
      final user = await repository.getProfile(userId);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
