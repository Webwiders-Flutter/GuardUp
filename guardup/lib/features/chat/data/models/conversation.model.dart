import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/assets.gen.dart';
import '../enums/conversation_type.enum.dart';
import '../enums/message_status.enum.dart';
import 'message.model.dart';
import 'participant.model.dart';

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

  static List<ConversationModel> get fakeData {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return [
      ConversationModel(
        id: 'conv_1',
        title: 'Vikram Singh',
        avatarUrl: Assets.images.profilePicture2.path,
        isVerified: true,
        type: ConversationType.direct,
        updatedAt: now.subtract(const Duration(minutes: 5)),
        customFormattedTime: '9:40 AM',
        lastMessage: MessageModel(
          id: 'msg_1',
          conversationId: 'conv_1',
          senderId: 'me',
          content: 'Just got into the elevator, 30 seconds a...',
          status: MessageStatus.read,
          createdAt: now.subtract(const Duration(minutes: 5)),
          isMe: true,
        ),
      ),
      ConversationModel(
        id: 'conv_2',
        title: 'David Sterling',
        avatarUrl: Assets.images.profilePicture.path,
        isVerified: false,
        type: ConversationType.direct,
        updatedAt: yesterday,
        customFormattedTime: 'Yesterday',
        lastMessage: MessageModel(
          id: 'msg_2',
          conversationId: 'conv_2',
          senderId: 'usr_david',
          content: 'Escort corridor cleared. LAX Terminal 4 st...',
          status: MessageStatus.delivered,
          createdAt: yesterday,
          isMe: false,
        ),
      ),
      ConversationModel(
        id: 'conv_3',
        title: 'Marcus Sterling',
        avatarUrl: Assets.images.profilePicture.path,
        isVerified: false,
        type: ConversationType.direct,
        updatedAt: DateTime(2026, 4, 26, 9, 0),
        customFormattedTime: 'Apr 26',
        lastMessage: MessageModel(
          id: 'msg_3',
          conversationId: 'conv_3',
          senderId: 'me',
          content: 'Booking confirmed for tomorrow, 9:00',
          status: MessageStatus.delivered,
          createdAt: DateTime(2026, 4, 26, 9, 0),
          isMe: true,
        ),
      ),
      ConversationModel(
        id: 'conv_4',
        title: 'Carlos Sterling',
        avatarUrl: Assets.images.profilePicture2.path,
        isVerified: false,
        type: ConversationType.direct,
        updatedAt: DateTime(2026, 4, 26, 9, 0),
        customFormattedTime: 'Apr 26',
        lastMessage: MessageModel(
          id: 'msg_4',
          conversationId: 'conv_4',
          senderId: 'me',
          content: 'Booking confirmed for tomorrow, 9:00',
          status: MessageStatus.delivered,
          createdAt: DateTime(2026, 4, 26, 9, 0),
          isMe: true,
        ),
      ),
      ConversationModel(
        id: 'conv_5',
        title: 'Marcus Sterling',
        avatarUrl: Assets.images.profilePicture.path,
        isVerified: false,
        type: ConversationType.direct,
        updatedAt: DateTime(2026, 4, 26, 9, 0),
        customFormattedTime: 'Apr 26',
        lastMessage: MessageModel(
          id: 'msg_5',
          conversationId: 'conv_5',
          senderId: 'me',
          content: 'Booking confirmed for tomorrow, 9:00',
          status: MessageStatus.delivered,
          createdAt: DateTime(2026, 4, 26, 9, 0),
          isMe: true,
        ),
      ),
      ConversationModel(
        id: 'conv_6',
        title: 'Carlos Sterling',
        avatarUrl: Assets.images.profilePicture.path,
        isVerified: false,
        type: ConversationType.direct,
        updatedAt: DateTime(2026, 4, 26, 9, 0),
        customFormattedTime: 'Apr 26',
        lastMessage: MessageModel(
          id: 'msg_6',
          conversationId: 'conv_6',
          senderId: 'me',
          content: 'Booking confirmed for tomorrow, 9:00',
          status: MessageStatus.delivered,
          createdAt: DateTime(2026, 4, 26, 9, 0),
          isMe: true,
        ),
      ),
      ConversationModel(
        id: 'conv_7',
        title: 'Carlos Sterling',
        avatarUrl: Assets.images.profilePicture2.path,
        isVerified: false,
        type: ConversationType.direct,
        updatedAt: DateTime(2026, 4, 26, 9, 0),
        customFormattedTime: 'Apr 26',
        lastMessage: MessageModel(
          id: 'msg_7',
          conversationId: 'conv_7',
          senderId: 'me',
          content: 'Booking confirmed for tomorrow, 9:00',
          status: MessageStatus.delivered,
          createdAt: DateTime(2026, 4, 26, 9, 0),
          isMe: true,
        ),
      ),
      ConversationModel(
        id: 'conv_8',
        title: 'Marcus Sterling',
        avatarUrl: Assets.images.profilePicture.path,
        isVerified: false,
        type: ConversationType.direct,
        updatedAt: DateTime(2026, 4, 26, 9, 0),
        customFormattedTime: 'Apr 26',
        lastMessage: MessageModel(
          id: 'msg_8',
          conversationId: 'conv_8',
          senderId: 'me',
          content: 'Booking confirmed for tomorrow, 9:00',
          status: MessageStatus.delivered,
          createdAt: DateTime(2026, 4, 26, 9, 0),
          isMe: true,
        ),
      ),
    ];
  }
}
