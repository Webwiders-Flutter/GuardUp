/// Type of chat conversation.
enum ConversationType {
  direct,
  group,
  support;

  bool get isDirect => this == ConversationType.direct;
  bool get isGroup => this == ConversationType.group;
  bool get isSupport => this == ConversationType.support;
}

