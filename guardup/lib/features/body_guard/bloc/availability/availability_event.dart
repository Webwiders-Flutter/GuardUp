import 'package:equatable/equatable.dart';

import '../../data/enum/week_day.enum.dart';

abstract class AvailabilityEvent extends Equatable {
  const AvailabilityEvent();

  @override
  List<Object?> get props => [];
}

/// Loads weekly availability rows for the owner.
final class AvailabilityStarted extends AvailabilityEvent {
  const AvailabilityStarted();
}

/// Toggles whether [day] is marked as available.
final class AvailabilityDayToggled extends AvailabilityEvent {
  const AvailabilityDayToggled(this.day);

  final WeekDay day;

  @override
  List<Object?> get props => [day];
}

/// Updates the start/end time strings for [day].
final class AvailabilityTimeChanged extends AvailabilityEvent {
  const AvailabilityTimeChanged(
    this.day, {
    this.fromTime,
    this.toTime,
  });

  final WeekDay day;
  final String? fromTime;
  final String? toTime;

  @override
  List<Object?> get props => [day, fromTime, toTime];
}

/// Saves all 7 weekday rows to `public.user_availabilities`.
final class AvailabilitySaved extends AvailabilityEvent {
  const AvailabilitySaved();
}
