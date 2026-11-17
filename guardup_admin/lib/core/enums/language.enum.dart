import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

enum LanguageType {
  @JsonValue('en')
  english('en', code: 'en', nativeName: 'English'),
  @JsonValue('hi')
  hindi('hi', code: 'hi', nativeName: 'हिंदी');

  final String apiValue;
  final String code;
  final String nativeName;

  const LanguageType(
    this.apiValue, {
    required this.code,
    required this.nativeName,
  });

  Locale get locale => Locale(code);

  static LanguageType fromString(String value) {
    final normalized = value.toLowerCase().trim();
    return LanguageType.values.firstWhere(
      (e) =>
          e.apiValue.toLowerCase() == normalized ||
          e.code.toLowerCase() == normalized,
      orElse: () => LanguageType.english,
    );
  }

  static LanguageType? tryFromString(String? value) {
    if (value == null) return null;
    final normalized = value.toLowerCase().trim();
    try {
      return LanguageType.values.firstWhere(
        (e) =>
            e.apiValue.toLowerCase() == normalized ||
            e.code.toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }
}
