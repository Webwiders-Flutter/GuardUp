import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class GetProfileEvent extends ProfileEvent {
  final String userId;

  const GetProfileEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateProfileEvent extends ProfileEvent {
  final UserEntity user;
  final File? imageFile;

  const UpdateProfileEvent({required this.user, this.imageFile});

  @override
  List<Object?> get props => [user, imageFile];
}
