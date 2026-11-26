import '/core/constants/api/json_keys.dart';
import '/shared/models/record_owner.model.dart';
import '../enum/week_day.enum.dart';

/// Payload for saving one day's schedule in `public.user_availabilities`.
class AvailabilityRequest {
  const AvailabilityRequest({
    required this.dayOfWeek,
    this.isAvailable = false,
    this.fromTime = '09:00 AM',
    this.toTime = '05:00 PM',
  });

  final WeekDay dayOfWeek;
  final bool isAvailable;
  final String fromTime;
  final String toTime;

  Map<String, dynamic> toJson({RecordOwner? owner}) {
    return <String, dynamic>{
      if (owner != null) owner.column: owner.id,
      JsonKeys.dayOfWeek: dayOfWeek.apiValue,
      JsonKeys.isAvailable: isAvailable,
      JsonKeys.fromTime: fromTime.trim(),
      JsonKeys.toTime: toTime.trim(),
    };
  }
}
