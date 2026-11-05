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

  static ConversationType fromApiValue(String? value) {
    if (value == null) return ConversationType.direct;
    return ConversationType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => ConversationType.direct,
    );
  }

  static ConversationType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return ConversationType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

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
