import 'package:freezed_annotation/freezed_annotation.dart';

/// Type of chat conversation.
enum ConversationType {
  @JsonValue('DIRECT')
  direct('DIRECT'),

  @JsonValue('GROUP')
  group('GROUP'),

  @JsonValue('SUPPORT')
  support('SUPPORT');

  final String apiValue;

  const ConversationType(this.apiValue);

  String get label {
    switch (this) {
      case ConversationType.direct:
        return 'Direct';
      case ConversationType.group:
        return 'Group';
      case ConversationType.support:
        return 'Support';
    }
  }

  bool get isDirect => this == ConversationType.direct;
  bool get isGroup => this == ConversationType.group;
  bool get isSupport => this == ConversationType.support;
}
