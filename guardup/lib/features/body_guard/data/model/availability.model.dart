import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/auth/auth.dart';
import '../enum/week_day.enum.dart';

part 'availability.model.freezed.dart';
part 'availability.model.g.dart';

/// Represents a bodyguard's scheduled operational availability window for a day of the week.
@freezed
abstract class AvailabilityModel with _$AvailabilityModel {
  const factory AvailabilityModel({
    required String id,
    required WeekDay weekDay,
    required DateTime fromDateTime,
    required DateTime toDateTime,
    @Default(true) bool isAvailable,
    UserModel? user,
  }) = _AvailabilityModel;

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityModelFromJson(json);

  static List<AvailabilityModel> get fakeData => fakeWeeklySchedule;
  static List<AvailabilityModel> get fakeWeeklySchedule => [
    AvailabilityModel(
      id: 'avail_mon',
      weekDay: WeekDay.monday,
      fromDateTime: DateTime(2026, 1, 1, 8, 0),
      toDateTime: DateTime(2026, 1, 1, 20, 0),
      isAvailable: true,
    ),
    AvailabilityModel(
      id: 'avail_tue',
      weekDay: WeekDay.tuesday,
      fromDateTime: DateTime(2026, 1, 1, 8, 0),
      toDateTime: DateTime(2026, 1, 1, 20, 0),
      isAvailable: true,
    ),
    AvailabilityModel(
      id: 'avail_wed',
      weekDay: WeekDay.wednesday,
      fromDateTime: DateTime(2026, 1, 1, 8, 0),
      toDateTime: DateTime(2026, 1, 1, 20, 0),
      isAvailable: true,
    ),
    AvailabilityModel(
      id: 'avail_thu',
      weekDay: WeekDay.thursday,
      fromDateTime: DateTime(2026, 1, 1, 8, 0),
      toDateTime: DateTime(2026, 1, 1, 20, 0),
      isAvailable: true,
    ),
    AvailabilityModel(
      id: 'avail_fri',
      weekDay: WeekDay.friday,
      fromDateTime: DateTime(2026, 1, 1, 8, 0),
      toDateTime: DateTime(2026, 1, 1, 22, 0),
      isAvailable: true,
    ),
    AvailabilityModel(
      id: 'avail_sat',
      weekDay: WeekDay.saturday,
      fromDateTime: DateTime(2026, 1, 1, 10, 0),
      toDateTime: DateTime(2026, 1, 1, 22, 0),
      isAvailable: true,
    ),
    AvailabilityModel(
      id: 'avail_sun',
      weekDay: WeekDay.sunday,
      fromDateTime: DateTime(2026, 1, 1, 10, 0),
      toDateTime: DateTime(2026, 1, 1, 18, 0),
      isAvailable: false,
    ),
  ];
}
