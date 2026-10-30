import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';

import '../repositories/profile_repository.dart';

class BlockUserUseCase {
  final ProfileRepository repository;

  BlockUserUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.blockUser(userId);
  }
}
