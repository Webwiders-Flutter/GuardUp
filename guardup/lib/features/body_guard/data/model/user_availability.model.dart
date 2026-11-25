import 'package:freezed_annotation/freezed_annotation.dart';

import '../enum/bodyguard_availability_status.enum.dart';
import '../enum/week_day.enum.dart';

part 'user_availability.model.freezed.dart';
part 'user_availability.model.g.dart';

WeekDay? _weekDayFromJson(dynamic value) {
  if (value == null) return null;
  return WeekDay.tryFromApiValue(value.toString());
}

String? _weekDayToJson(WeekDay? day) => day?.name.toLowerCase();

int? _parseTimeToMinutes(String timeStr) {
  final clean = timeStr.trim().toUpperCase();
  if (clean.isEmpty) return null;

  final isPm = clean.endsWith('PM');
  final isAm = clean.endsWith('AM');
  final rawTime = clean.replaceAll('AM', '').replaceAll('PM', '').trim();
  final parts = rawTime.split(':');
  if (parts.isEmpty) return null;

  int? hours = int.tryParse(parts[0]);
  final minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  if (hours == null) return null;

  if (isPm && hours < 12) {
    hours += 12;
  } else if (isAm && hours == 12) {
    hours = 0;
  }

  return hours * 60 + minutes;
}

/// One row of `user_availabilities`: a user's working hours for one day.
@freezed
abstract class UserAvailabilityModel with _$UserAvailabilityModel {
  const UserAvailabilityModel._();

  const factory UserAvailabilityModel({
    required String id,
    String? userId,
    String? bodyguardId,
    @JsonKey(fromJson: _weekDayFromJson, toJson: _weekDayToJson)
    WeekDay? dayOfWeek,
    @Default(true) bool isAvailable,
    @Default('09:00 AM') String fromTime,
    @Default('05:00 PM') String toTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserAvailabilityModel;

  factory UserAvailabilityModel.fromJson(Map<String, dynamic> json) =>
      _$UserAvailabilityModelFromJson(json);

  /// Checks whether this availability window covers the specified [dateTime].
  bool isAvailableAt(DateTime dateTime) {
    if (!isAvailable || dayOfWeek == null) return false;
    if (dateTime.weekday != dayOfWeek!.weekdayNumber) return false;

    final fromMinutes = _parseTimeToMinutes(fromTime);
    final toMinutes = _parseTimeToMinutes(toTime);
    if (fromMinutes == null || toMinutes == null) return false;

    final currentMinutes = dateTime.hour * 60 + dateTime.minute;
    if (fromMinutes <= toMinutes) {
      return currentMinutes >= fromMinutes && currentMinutes <= toMinutes;
    } else {
      // Overnight working shift spanning midnight
      return currentMinutes >= fromMinutes || currentMinutes <= toMinutes;
    }
  }

  /// Calculates dynamic status for this specific day slot.
  BodyguardAvailabilityStatus get currentStatus {
    if (dayOfWeek == null) return BodyguardAvailabilityStatus.notSet;
    if (!isAvailable) return BodyguardAvailabilityStatus.notAvailable;
    return isAvailableAt(DateTime.now())
        ? BodyguardAvailabilityStatus.available
        : BodyguardAvailabilityStatus.notAvailable;
  }
}
