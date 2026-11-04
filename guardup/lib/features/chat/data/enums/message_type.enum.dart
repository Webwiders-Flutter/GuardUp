import 'package:freezed_annotation/freezed_annotation.dart';

/// Semantic type of content sent in a chat message.
enum MessageType {
  @JsonValue('TEXT')
  text('TEXT'),

  @JsonValue('IMAGE')
  image('IMAGE'),

  @JsonValue('FILE')
  file('FILE'),

  @JsonValue('LOCATION')
  location('LOCATION'),

  @JsonValue('AUDIO')
  audio('AUDIO');

  final String apiValue;

  const MessageType(this.apiValue);

  static MessageType fromApiValue(String? value) {
    if (value == null) return MessageType.text;
    return MessageType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => MessageType.text,
    );
  }

  static MessageType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return MessageType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isText => this == MessageType.text;
  bool get isImage => this == MessageType.image;
  bool get isFile => this == MessageType.file;
  bool get isLocation => this == MessageType.location;
  bool get isAudio => this == MessageType.audio;
}
