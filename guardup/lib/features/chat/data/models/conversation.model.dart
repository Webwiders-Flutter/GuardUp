import '/gen/assets.gen.dart';
import '../enums/conversation_type.enum.dart';
import '../enums/message_status.enum.dart';
import 'message.model.dart';
import 'participant.model.dart';

/// Represents a chat thread between users or operatives.
class ConversationModel {
  final String id;
  final String title;
  final String? avatarUrl;
  final bool isVerified;
  final ConversationType type;
  final List<ParticipantModel> participants;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final String? customFormattedTime;

  const ConversationModel({
    required this.id,
    required this.title,
    this.avatarUrl,
    this.isVerified = false,
    this.type = ConversationType.direct,
    this.participants = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.customFormattedTime,
  });

  /// Readable snippet text from the last message.
  String get snippet => lastMessage?.content ?? '';

  /// Formatted relative or calendar timestamp matching design.
  String get displayTime {
    if (customFormattedTime != null && customFormattedTime!.isNotEmpty) {
      return customFormattedTime!;
    }

    final now = DateTime.now();
    if (updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day) {
      final hour = updatedAt.hour > 12
          ? updatedAt.hour - 12
          : (updatedAt.hour == 0 ? 12 : updatedAt.hour);
      final minute = updatedAt.minute.toString().padLeft(2, '0');
      final period = updatedAt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (updatedAt.year == yesterday.year &&
        updatedAt.month == yesterday.month &&
        updatedAt.day == yesterday.day) {
      return 'Yesterday';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[updatedAt.month - 1]} ${updatedAt.day}';
  }

  /// Whether the conversation occurred today.
  bool get isToday {
    final now = DateTime.now();
    return updatedAt.year == now.year &&
        updatedAt.month == now.month &&
        updatedAt.day == now.day;
  }

  ConversationModel copyWith({
    String? id,
    String? title,
    String? avatarUrl,
    bool? isVerified,
    ConversationType? type,
    List<ParticipantModel>? participants,
    MessageModel? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    String? customFormattedTime,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
      customFormattedTime: customFormattedTime ?? this.customFormattedTime,
    );
  }

  /// Curated fake conversations matching the exact screen mockup.
  static List<ConversationModel> get fakeConversations {
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

