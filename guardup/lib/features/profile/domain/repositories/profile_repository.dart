import 'dart:io';

import 'package:guardup/features/auth/domain/entities/user_entity.dart';

import 'package:guardup/core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class ProfileRepository {
  Future<UserEntity> getProfile(String userId);
  Future<void> updateProfile(UserEntity user);
  Future<String> uploadProfileImage(String userId, File imageFile);
  Future<void> updatePreferences({
    required String userId,
    required List<String> interests,
    required List<String> preferredDestinations,
  });

  Future<Either<Failure, void>> blockUser(String userId);
  Future<Either<Failure, void>> unblockUser(String userId);
  Future<Either<Failure, List<String>>> getBlockedUserIds();
  Future<Either<Failure, List<UserEntity>>> getBlockedUsers({
    int page = 1,
    int limit = 20,
  });
}
