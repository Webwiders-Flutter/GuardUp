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

  static MessageStatus fromApiValue(String? value) {
    if (value == null) return MessageStatus.sent;
    return MessageStatus.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => MessageStatus.sent,
    );
  }

  static MessageStatus? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return MessageStatus.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isSending => this == MessageStatus.sending;
  bool get isSent => this == MessageStatus.sent;
  bool get isDelivered => this == MessageStatus.delivered;
  bool get isRead => this == MessageStatus.read;
}
