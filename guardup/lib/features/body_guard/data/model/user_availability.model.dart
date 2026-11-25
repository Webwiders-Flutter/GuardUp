import 'package:freezed_annotation/freezed_annotation.dart';

import '../enum/week_day.enum.dart';

part 'user_availability.model.freezed.dart';
part 'user_availability.model.g.dart';

WeekDay? _weekDayFromJson(dynamic value) {
  if (value == null) return null;
  return WeekDay.tryFromApiValue(value.toString());
}

String? _weekDayToJson(WeekDay? day) => day?.name.toLowerCase();

/// One row of `user_availabilities`: a user's working hours for one day.
@freezed
abstract class UserAvailabilityModel with _$UserAvailabilityModel {
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
}
