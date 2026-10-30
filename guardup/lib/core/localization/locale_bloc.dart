import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'domain/repositories/localization_repository.dart';

part 'locale_event.dart';
part 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final LocalizationRepository _localizationRepository;

  LocaleBloc({required LocalizationRepository localizationRepository})
    : _localizationRepository = localizationRepository,
      super(const LocaleState(Locale('en'))) {
    on<ChangeLocale>(_onChangeLocale);
    on<LoadLocale>(_onLoadLocale);
  }

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<LocaleState> emit,
  ) async {
    await _localizationRepository.saveLocale(event.locale.languageCode);
    emit(LocaleState(event.locale));
  }

  Future<void> _onLoadLocale(
    LoadLocale event,
    Emitter<LocaleState> emit,
  ) async {
    final savedLocaleCode = await _localizationRepository.getLocale();
    if (savedLocaleCode != null) {
      emit(LocaleState(Locale(savedLocaleCode)));
    }
  }
}
