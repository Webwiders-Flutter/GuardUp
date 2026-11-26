import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/message_status.enum.dart';
import '../enums/message_type.enum.dart';

import '../fixtures/chat.fixtures.dart';

part 'message.model.freezed.dart';
part 'message.model.g.dart';

/// Represents a single chat message exchanged within a conversation.
@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    String? highlightedText,
    String? vehicleBadge,
    @Default(MessageType.text) MessageType type,
    @Default(MessageStatus.sent) MessageStatus status,
    required DateTime createdAt,
    @Default(false) bool isMe,
    String? customFormattedTime,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  /// Curated fake messages matching the live escort chat thread screenshot.
  @Deprecated('Use messageFixtures from data/fixtures/chat.fixtures.dart')
  static List<MessageModel> get fakeData => messageFixtures;
}
