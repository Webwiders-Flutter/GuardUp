import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/message_status.enum.dart';
import '../enums/message_type.enum.dart';

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

  static List<MessageModel> get fakeData => fakeEscortChatMessages;

  /// Curated fake messages matching the live escort chat thread screenshot.
  static List<MessageModel> get fakeEscortChatMessages => [
    MessageModel(
      id: 'chat_msg_1',
      conversationId: 'conv_1',
      senderId: 'usr_vikram',
      content: 'Hello Rahul, I have arrived at your pickup location outside the main lobby.',
      status: MessageStatus.read,
      createdAt: DateTime(2026, 4, 28, 9, 42),
      customFormattedTime: '9:42 AM',
      isMe: false,
    ),
    MessageModel(
      id: 'chat_msg_2',
      conversationId: 'conv_1',
      senderId: 'current_user',
      content: 'Great, coming down now. Wearing a dark suit.',
      status: MessageStatus.read,
      createdAt: DateTime(2026, 4, 28, 9, 43),
      customFormattedTime: '9:43 AM',
      isMe: true,
    ),
    MessageModel(
      id: 'chat_msg_3',
      conversationId: 'conv_1',
      senderId: 'usr_vikram',
      content: 'Understood, perimeter secured. Standing by at the north entrance with vehicle running.',
      status: MessageStatus.read,
      createdAt: DateTime(2026, 4, 28, 9, 43),
      customFormattedTime: '9:43 AM',
      isMe: false,
    ),
    MessageModel(
      id: 'chat_msg_4',
      conversationId: 'conv_1',
      senderId: 'usr_vikram',
      content: 'Vehicle hazard lights are on for identification. Armored Escalade license ',
      highlightedText: 'MH 01 EQ 2404.',
      vehicleBadge: 'Black Cadillac Escalade B6 Armor',
      status: MessageStatus.read,
      createdAt: DateTime(2026, 4, 28, 9, 44),
      customFormattedTime: '9:44 AM',
      isMe: false,
    ),
    MessageModel(
      id: 'chat_msg_5',
      conversationId: 'conv_1',
      senderId: 'current_user',
      content: 'Just got into the elevator, 30 seconds away.',
      status: MessageStatus.read,
      createdAt: DateTime(2026, 4, 28, 9, 44),
      customFormattedTime: '9:44 AM',
      isMe: true,
    ),
    MessageModel(
      id: 'chat_msg_6',
      conversationId: 'conv_1',
      senderId: 'usr_vikram',
      content: 'Understood, perimeter secured. Standing by at the north entrance with vehicle running.',
      status: MessageStatus.read,
      createdAt: DateTime(2026, 4, 28, 9, 45),
      customFormattedTime: '9:45 AM',
      isMe: false,
    ),
  ];
}
