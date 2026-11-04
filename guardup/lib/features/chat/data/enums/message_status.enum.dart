/// Delivery and read status of a chat message.
enum MessageStatus {
  sending,
  sent,
  delivered,
  read;

  bool get isSending => this == MessageStatus.sending;
  bool get isSent => this == MessageStatus.sent;
  bool get isDelivered => this == MessageStatus.delivered;
  bool get isRead => this == MessageStatus.read;
}

