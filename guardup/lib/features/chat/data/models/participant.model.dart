import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guardup/features/auth/auth.dart';

import '/gen/assets.gen.dart';

part 'participant.model.freezed.dart';
part 'participant.model.g.dart';

/// Represents a user or operative participating in a conversation.
@freezed
abstract class ParticipantModel with _$ParticipantModel {
  const factory ParticipantModel({
    required String id,
    required String name,
    String? avatarUrl,
    @Default(false) bool isVerified,
    @Default(UserRole.guard) UserRole role,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
    String? clearanceLevel,
  }) = _ParticipantModel;

  factory ParticipantModel.fromJson(Map<String, dynamic> json) =>
      _$ParticipantModelFromJson(json);

  static List<ParticipantModel> get fakeData => fakeParticipants;
  static List<ParticipantModel> get fakeParticipants => [
    ParticipantModel(
      id: 'usr_vikram',
      name: 'Vikram Singh',
      avatarUrl: Assets.images.profilePicture2.path,
      isVerified: true,
      role: .guard,
      isOnline: true,
      clearanceLevel: 'Executive VIP Escort',
    ),
    ParticipantModel(
      id: 'usr_david',
      name: 'David Sterling',
      avatarUrl: Assets.images.profilePicture.path,
      isVerified: false,
      role: .guard,
      isOnline: false,
      clearanceLevel: 'Armed Transport',
    ),
    ParticipantModel(
      id: 'usr_marcus',
      name: 'Marcus Sterling',
      avatarUrl: Assets.images.profilePicture.path,
      isVerified: false,
      role: .guard,
      isOnline: false,
      clearanceLevel: 'Close Protection',
    ),
    ParticipantModel(
      id: 'usr_carlos',
      name: 'Carlos Sterling',
      avatarUrl: Assets.images.profilePicture2.path,
      isVerified: false,
      role: .guard,
      isOnline: false,
      clearanceLevel: 'Static Perimeter',
    ),
  ];
}
