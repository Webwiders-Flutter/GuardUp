import 'dart:async';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/constants/app_local_storage_keys.dart';
import '/core/di/injection_container.dart';
import '/core/services/local_storage/local_storage.service.dart';
import '/core/services/local_storage/storage.dart';
import '/features/notifications/bloc/user_device/user_device_cubit.dart';
import '../enum/language.enum.dart';
import 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  final LocalStorage _storage;

  LanguageCubit({LocalStorage? storage})
    : _storage = storage ?? PrefsStorageService.instance,
      super(const LanguageState(isLoading: true)) {
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    try {
      final languageStr = await _storage.read<String>(
        AppLocalStorageKeys.language,
      );
      if (languageStr != null) {
        final language = LanguageType.fromApiValue(languageStr);
        emit(state.copyWith(language: language, isLoading: false));
        return;
      }
    } catch (_) {}
    emit(state.copyWith(language: LanguageType.english, isLoading: false));
  }

  Future<void> changeLanguage(LanguageType language) async {
    if (state.language == language && !state.isLoading) return;
    emit(state.copyWith(language: language, isLoading: false));
    try {
      await _storage.write<String>(
        key: AppLocalStorageKeys.language,
        value: language.apiValue,
      );
      if (sl.isRegistered<UserDeviceCubit>()) {
        unawaited(sl<UserDeviceCubit>().updateDeviceLanguage(language.apiValue));
      }
    } catch (_) {}
  }

  bool get isArabic => state.isArabic;
  bool get isEnglish => state.isEnglish;
  Locale get currentLocale => state.locale;
}
