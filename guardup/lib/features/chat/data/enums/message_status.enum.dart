import 'package:freezed_annotation/freezed_annotation.dart';

/// Delivery and read status of a chat message.
enum MessageStatus {
  @JsonValue('SENDING')
  sending('SENDING'),

  @JsonValue('SENT')
  sent('SENT'),

  @JsonValue('DELIVERED')
  delivered('DELIVERED'),

  @JsonValue('READ')
  read('READ');

  final String apiValue;

  const MessageStatus(this.apiValue);

  bool get isSending => this == MessageStatus.sending;
  bool get isSent => this == MessageStatus.sent;
  bool get isDelivered => this == MessageStatus.delivered;
  bool get isRead => this == MessageStatus.read;
}
