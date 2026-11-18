import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Day of the week stored in `user_availabilities.day_of_week`
/// (the mobile app writes lowercase names).
enum WeekDay {
  @JsonValue('monday')
  monday('monday'),

  @JsonValue('tuesday')
  tuesday('tuesday'),

  @JsonValue('wednesday')
  wednesday('wednesday'),

  @JsonValue('thursday')
  thursday('thursday'),

  @JsonValue('friday')
  friday('friday'),

  @JsonValue('saturday')
  saturday('saturday'),

  @JsonValue('sunday')
  sunday('sunday');

  final String apiValue;

  const WeekDay(this.apiValue);

  String label([AppLocalizations? l10n]) {
    switch (this) {
      case WeekDay.monday:
        return 'Monday';
      case WeekDay.tuesday:
        return 'Tuesday';
      case WeekDay.wednesday:
        return 'Wednesday';
      case WeekDay.thursday:
        return 'Thursday';
      case WeekDay.friday:
        return 'Friday';
      case WeekDay.saturday:
        return 'Saturday';
      case WeekDay.sunday:
        return 'Sunday';
    }
  }
}
