import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

enum LanguageType {
  @JsonValue('en')
  english('en'),
  @JsonValue('ar')
  arabic('ar');

  final String apiValue;

  const LanguageType(this.apiValue);

  String get code => apiValue;

  String get nativeName {
    switch (this) {
      case LanguageType.english:
        return 'English';
      case LanguageType.arabic:
        return 'العربية';
    }
  }

  Locale get locale => Locale(code);

  static LanguageType fromApiValue(String? value) {
    if (value == null) return LanguageType.english;
    final normalized = value.toLowerCase().trim();
    return LanguageType.values.firstWhere(
      (e) =>
          e.apiValue.toLowerCase() == normalized ||
          e.code.toLowerCase() == normalized,
      orElse: () => LanguageType.english,
    );
  }

  static LanguageType? tryFromApiValue(String? value) {
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
