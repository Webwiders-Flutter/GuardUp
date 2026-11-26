import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/enum/week_day.enum.dart';

class AvailabilityDraft extends Equatable {
  const AvailabilityDraft({
    this.isAvailable = false,
    this.fromTime = '09:00 AM',
    this.toTime = '12:00 PM',
  });

  final bool isAvailable;
  final String fromTime;
  final String toTime;

  AvailabilityDraft copyWith({
    bool? isAvailable,
    String? fromTime,
    String? toTime,
  }) {
    return AvailabilityDraft(
      isAvailable: isAvailable ?? this.isAvailable,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
    );
  }

  @override
  List<Object?> get props => [isAvailable, fromTime, toTime];
}

class AvailabilityState extends Equatable {
  const AvailabilityState({
    required this.schedule,
    this.loadStatus = const ApiState.initial(),
    this.saveStatus = const ApiState.initial(),
  });

  factory AvailabilityState.initial() => AvailabilityState(
    schedule: {
      for (final day in WeekDay.values) day: const AvailabilityDraft(),
    },
  );

  final Map<WeekDay, AvailabilityDraft> schedule;
  final ApiState<void> loadStatus;
  final ApiState<void> saveStatus;

  List<WeekDay> get selectedDays => [
    for (final day in WeekDay.values)
      if (schedule[day]?.isAvailable ?? false) day,
  ];

  AvailabilityState copyWith({
    Map<WeekDay, AvailabilityDraft>? schedule,
    ApiState<void>? loadStatus,
    ApiState<void>? saveStatus,
  }) {
    return AvailabilityState(
      schedule: schedule ?? this.schedule,
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }

  @override
  List<Object?> get props => [schedule, loadStatus, saveStatus];
}
