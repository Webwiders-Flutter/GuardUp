import '/gen/assets.gen.dart';
import '../enums/conversation_type.enum.dart';
import '../enums/message_status.enum.dart';
import '../models/conversation.model.dart';
import '../models/message.model.dart';
import '../models/participant.model.dart';

/// Prototype messages matching the live escort chat thread.
final List<MessageModel> messageFixtures = [
  MessageModel(
    id: 'chat_msg_1',
    conversationId: 'conv_1',
    senderId: 'usr_vikram',
    content:
        'Hello Rahul, I have arrived at your pickup location outside the main lobby.',
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
    content:
        'Understood, perimeter secured. Standing by at the north entrance with vehicle running.',
    status: MessageStatus.read,
    createdAt: DateTime(2026, 4, 28, 9, 43),
    customFormattedTime: '9:43 AM',
    isMe: false,
  ),
  MessageModel(
    id: 'chat_msg_4',
    conversationId: 'conv_1',
    senderId: 'usr_vikram',
    content:
        'Vehicle hazard lights are on for identification. Armored Escalade license ',
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
    content:
        'Understood, perimeter secured. Standing by at the north entrance with vehicle running.',
    status: MessageStatus.read,
    createdAt: DateTime(2026, 4, 28, 9, 45),
    customFormattedTime: '9:45 AM',
    isMe: false,
  ),
];

/// Prototype participants for chat previews.
final List<ParticipantModel> participantFixtures = [
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
  ),
];

/// Prototype conversations for the chat list screen.
final List<ConversationModel> conversationFixtures = [
  ConversationModel(
    id: 'conv_1',
    title: 'Vikram Singh',
    avatarUrl: Assets.images.profilePicture2.path,
    isVerified: true,
    type: ConversationType.direct,
    updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    customFormattedTime: '9:40 AM',
    lastMessage: MessageModel(
      id: 'msg_1',
      conversationId: 'conv_1',
      senderId: 'me',
      content: 'Just got into the elevator, 30 seconds a...',
      status: MessageStatus.read,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isMe: true,
    ),
  ),
  ConversationModel(
    id: 'conv_2',
    title: 'David Sterling',
    avatarUrl: Assets.images.profilePicture.path,
    isVerified: false,
    type: ConversationType.direct,
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    customFormattedTime: 'Yesterday',
    lastMessage: MessageModel(
      id: 'msg_2',
      conversationId: 'conv_2',
      senderId: 'usr_david',
      content: 'Escort corridor cleared. LAX Terminal 4 st...',
      status: MessageStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
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
];
