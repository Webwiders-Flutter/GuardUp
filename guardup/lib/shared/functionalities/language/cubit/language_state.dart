import 'dart:ui';

import 'package:equatable/equatable.dart';

import '../enum/language.enum.dart';

class LanguageState extends Equatable {
  final LanguageType language;
  final bool isLoading;

  const LanguageState({
    this.language = LanguageType.english,
    this.isLoading = false,
  });

  Locale get locale => language.locale;
  bool get isArabic => language == LanguageType.arabic;
  bool get isEnglish => language == LanguageType.english;

  LanguageState copyWith({
    LanguageType? language,
    bool? isLoading,
  }) {
    return LanguageState(
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [language, isLoading];
}
