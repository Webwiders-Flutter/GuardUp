import '/features/auth/auth.dart';
import '../enum/week_day.enum.dart';

/// Represents a bodyguard's scheduled operational availability window for a day of the week.
class AvailabilityModel {
  final String id;
  final WeekDay weekDay;
  final DateTime fromDateTime;
  final DateTime toDateTime;
  final bool isAvailable;
  final UserModel? user;

  const AvailabilityModel({
    required this.id,
    required this.weekDay,
    required this.fromDateTime,
    required this.toDateTime,
    this.isAvailable = true,
    this.user,
  });

  /// Readable time string (e.g. "09:00 AM - 06:00 PM").
  String get formattedTimeRange {
    if (!isAvailable) return 'Unavailable';
    return '${_formatTime(fromDateTime)} - ${_formatTime(toDateTime)}';
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  AvailabilityModel copyWith({
    String? id,
    WeekDay? weekDay,
    DateTime? fromDateTime,
    DateTime? toDateTime,
    bool? isAvailable,
    UserModel? user,
  }) {
    return AvailabilityModel(
      id: id ?? this.id,
      weekDay: weekDay ?? this.weekDay,
      fromDateTime: fromDateTime ?? this.fromDateTime,
      toDateTime: toDateTime ?? this.toDateTime,
      isAvailable: isAvailable ?? this.isAvailable,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekDay': weekDay.apiValue,
      'fromDateTime': fromDateTime.toIso8601String(),
      'toDateTime': toDateTime.toIso8601String(),
      'isAvailable': isAvailable,
      if (user != null) 'user': user!.toJson(),
    };
  }

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      id: json['id'] as String? ?? '',
      weekDay: WeekDay.fromApiValue(json['weekDay'] as String?),
      fromDateTime: DateTime.tryParse(json['fromDateTime'] as String? ?? '') ??
          DateTime(2026, 1, 1, 9, 0),
      toDateTime: DateTime.tryParse(json['toDateTime'] as String? ?? '') ??
          DateTime(2026, 1, 1, 18, 0),
      isAvailable: json['isAvailable'] as bool? ?? true,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Curated weekly schedule fake data.
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

