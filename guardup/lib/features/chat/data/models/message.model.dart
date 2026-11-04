import '../enums/message_status.enum.dart';
import '../enums/message_type.enum.dart';

/// Represents a single chat message exchanged within a conversation.
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String? highlightedText;
  final String? vehicleBadge;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final bool isMe;
  final String? customFormattedTime;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.highlightedText,
    this.vehicleBadge,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.isMe = false,
    this.customFormattedTime,
  });

  /// Readable formatted timestamp (e.g. "9:42 AM").
  String get displayTime {
    if (customFormattedTime != null && customFormattedTime!.isNotEmpty) {
      return customFormattedTime!;
    }
    final hour = createdAt.hour > 12
        ? createdAt.hour - 12
        : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    String? highlightedText,
    String? vehicleBadge,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    bool? isMe,
    String? customFormattedTime,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      highlightedText: highlightedText ?? this.highlightedText,
      vehicleBadge: vehicleBadge ?? this.vehicleBadge,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isMe: isMe ?? this.isMe,
      customFormattedTime: customFormattedTime ?? this.customFormattedTime,
    );
  }

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
