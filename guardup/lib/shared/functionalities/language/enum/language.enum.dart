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

}
