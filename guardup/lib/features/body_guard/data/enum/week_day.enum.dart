import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Day of the week stored in `user_availabilities.day_of_week`.
///
/// The database stores lowercase names (`monday` … `sunday`), matching the
/// admin `WeekDay` enum. Parse with `WeekDay.values.fromValue(...)`, which is
/// case-insensitive, so legacy uppercase values still resolve.
enum WeekDay {
  @JsonValue('monday')
  monday('monday', 1),

  @JsonValue('tuesday')
  tuesday('tuesday', 2),

  @JsonValue('wednesday')
  wednesday('wednesday', 3),

  @JsonValue('thursday')
  thursday('thursday', 4),

  @JsonValue('friday')
  friday('friday', 5),

  @JsonValue('saturday')
  saturday('saturday', 6),

  @JsonValue('sunday')
  sunday('sunday', 7);

  final String apiValue;

  /// ISO weekday number, matching [DateTime.weekday] (Monday = 1).
  final int weekdayNumber;

  const WeekDay(this.apiValue, this.weekdayNumber);

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

  String shortLabel([AppLocalizations? l10n]) => label(l10n).substring(0, 3);

  /// Monday to Friday — the default working days for a new schedule.
  bool get isWeekday => weekdayNumber <= DateTime.friday;

  static WeekDay fromDateTime(DateTime dateTime) =>
      WeekDay.values.firstWhere((e) => e.weekdayNumber == dateTime.weekday);
}
