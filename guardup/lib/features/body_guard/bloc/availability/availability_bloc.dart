import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/shared/models/record_owner.model.dart';
import '../../data/enum/week_day.enum.dart';
import '../../data/model/availability_request.model.dart';
import '../../data/repositories/availability.repository.dart';
import 'availability_event.dart';
import 'availability_state.dart';

export 'availability_event.dart';
export 'availability_state.dart';

/// Manages weekly availability schedule for an account or managed bodyguard.
class AvailabilityBloc extends Bloc<AvailabilityEvent, AvailabilityState> {
  AvailabilityBloc(this._repository, {required this.owner})
    : super(AvailabilityState.initial()) {
    on<AvailabilityStarted>(_onStarted, transformer: restartable());
    on<AvailabilityDayToggled>(_onDayToggled);
    on<AvailabilityTimeChanged>(_onTimeChanged);
    on<AvailabilitySaved>(_onSaved);
  }

  final AvailabilityRepository _repository;
  final RecordOwner owner;

  Future<void> _onStarted(
    AvailabilityStarted event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (owner.id.isEmpty) {
      emit(
        AvailabilityState(
          schedule: _defaultSchedule(),
          loadStatus: const ApiState.success(null),
        ),
      );
      return;
    }

    emit(state.copyWith(loadStatus: const ApiState.loading()));

    try {
      final rows = await asyncHandler(() => _repository.getFor(owner));

      final schedule = <WeekDay, AvailabilityDraft>{
        for (final day in WeekDay.values) day: const AvailabilityDraft(),
      };

      if (rows.isNotEmpty) {
        for (final row in rows) {
          final day = row.dayOfWeek;
          if (day == null) continue;
          final existing = schedule[day]!;
          schedule[day] = AvailabilityDraft(
            isAvailable: row.isAvailable,
            fromTime: row.fromTime.isNotEmpty
                ? row.fromTime
                : existing.fromTime,
            toTime: row.toTime.isNotEmpty ? row.toTime : existing.toTime,
          );
        }
      } else {
        schedule.addAll(_defaultSchedule());
      }

      emit(
        state.copyWith(
          schedule: schedule,
          loadStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(loadStatus: ApiState.failure(e.message, error: e)));
    }
  }

  Map<WeekDay, AvailabilityDraft> _defaultSchedule() {
    return {
      for (final day in WeekDay.values)
        day: const AvailabilityDraft(isAvailable: false),
    };
  }

  void _onDayToggled(
    AvailabilityDayToggled event,
    Emitter<AvailabilityState> emit,
  ) {
    final current = state.schedule[event.day] ?? const AvailabilityDraft();
    final updated = Map<WeekDay, AvailabilityDraft>.from(state.schedule)
      ..[event.day] = current.copyWith(isAvailable: !current.isAvailable);
    emit(state.copyWith(schedule: updated));
  }

  void _onTimeChanged(
    AvailabilityTimeChanged event,
    Emitter<AvailabilityState> emit,
  ) {
    final current = state.schedule[event.day] ?? const AvailabilityDraft();
    final updated = Map<WeekDay, AvailabilityDraft>.from(state.schedule)
      ..[event.day] = current.copyWith(
        fromTime: event.fromTime,
        toTime: event.toTime,
      );
    emit(state.copyWith(schedule: updated));
  }

  Future<void> _onSaved(
    AvailabilitySaved event,
    Emitter<AvailabilityState> emit,
  ) async {
    if (owner.id.isEmpty) return;

    emit(state.copyWith(saveStatus: const ApiState.loading()));

    final requests = [
      for (final day in WeekDay.values)
        AvailabilityRequest(
          dayOfWeek: day,
          isAvailable: state.schedule[day]?.isAvailable ?? false,
          fromTime: state.schedule[day]?.fromTime ?? '09:00 AM',
          toTime: state.schedule[day]?.toTime ?? '08:00 PM',
        ),
    ];

    try {
      await asyncHandler(() => _repository.save(owner, requests));
      emit(state.copyWith(saveStatus: const ApiState.success(null)));
    } on ApiException catch (e) {
      emit(state.copyWith(saveStatus: ApiState.failure(e.message, error: e)));
    }
  }
}
