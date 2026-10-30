import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';
import 'package:guardup/features/profile/domain/repositories/profile_repository.dart';

class GetBlockedUsersUseCase {
  final ProfileRepository repository;

  GetBlockedUsersUseCase(this.repository);

  Future<Either<Failure, List<UserEntity>>> call({
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getBlockedUsers(page: page, limit: limit);
  }
}
