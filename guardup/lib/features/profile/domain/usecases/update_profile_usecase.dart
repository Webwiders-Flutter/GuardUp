import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:guardup/core/error/failures.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';

import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(
    UserEntity user, {
    File? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        final imageUrl = await repository.uploadProfileImage(
          user.id,
          imageFile,
        );
        user = user.copyWith(profileImage: imageUrl);
      }
      await repository.updateProfile(user);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
