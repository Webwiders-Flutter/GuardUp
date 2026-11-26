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

  bool get isText => this == MessageType.text;
  bool get isImage => this == MessageType.image;
  bool get isFile => this == MessageType.file;
  bool get isLocation => this == MessageType.location;
  bool get isAudio => this == MessageType.audio;
}
