import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guardup/features/auth/auth.dart';

import '../fixtures/chat.fixtures.dart';

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

  @Deprecated('Use participantFixtures from data/fixtures/chat.fixtures.dart')
  static List<ParticipantModel> get fakeData => participantFixtures;
}
