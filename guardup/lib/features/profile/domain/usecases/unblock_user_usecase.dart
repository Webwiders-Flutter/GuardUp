import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';
import 'package:guardup/features/profile/domain/repositories/profile_repository.dart';

class UnblockUserUseCase {
  final ProfileRepository repository;

  UnblockUserUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.unblockUser(userId);
  }
}
