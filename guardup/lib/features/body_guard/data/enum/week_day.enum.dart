import 'package:freezed_annotation/freezed_annotation.dart';

/// Enum representing days of the week for bodyguard scheduling and availability.
enum WeekDay {
  @JsonValue('MONDAY')
  monday('MONDAY', 'Monday', 'Mon', 1),

  @JsonValue('TUESDAY')
  tuesday('TUESDAY', 'Tuesday', 'Tue', 2),

  @JsonValue('WEDNESDAY')
  wednesday('WEDNESDAY', 'Wednesday', 'Wed', 3),

  @JsonValue('THURSDAY')
  thursday('THURSDAY', 'Thursday', 'Thu', 4),

  @JsonValue('FRIDAY')
  friday('FRIDAY', 'Friday', 'Fri', 5),

  @JsonValue('SATURDAY')
  saturday('SATURDAY', 'Saturday', 'Sat', 6),

  @JsonValue('SUNDAY')
  sunday('SUNDAY', 'Sunday', 'Sun', 7);

  final String apiValue;
  final String label;
  final String shortLabel;
  final int weekdayNumber;

  const WeekDay(this.apiValue, this.label, this.shortLabel, this.weekdayNumber);

  static WeekDay fromApiValue(String? value) {
    if (value == null) return WeekDay.monday;
    return WeekDay.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => WeekDay.monday,
    );
  }

  static WeekDay? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return WeekDay.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  static WeekDay fromDateTime(DateTime dateTime) {
    return WeekDay.values.firstWhere(
      (e) => e.weekdayNumber == dateTime.weekday,
      orElse: () => WeekDay.monday,
    );
  }
}
