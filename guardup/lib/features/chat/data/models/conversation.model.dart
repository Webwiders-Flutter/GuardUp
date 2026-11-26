import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/conversation_type.enum.dart';
import 'message.model.dart';
import 'participant.model.dart';

import '../fixtures/chat.fixtures.dart';

part 'conversation.model.freezed.dart';
part 'conversation.model.g.dart';

/// Represents a chat thread between users or operatives.
@freezed
abstract class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required String id,
    required String title,
    String? avatarUrl,
    @Default(false) bool isVerified,
    @Default(ConversationType.direct) ConversationType type,
    @Default([]) List<ParticipantModel> participants,
    MessageModel? lastMessage,
    @Default(0) int unreadCount,
    required DateTime updatedAt,
    String? customFormattedTime,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  @Deprecated('Use conversationFixtures from data/fixtures/chat.fixtures.dart')
  static List<ConversationModel> get fakeData => conversationFixtures;
}
