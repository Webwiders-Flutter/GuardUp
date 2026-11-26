import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/shared/models/record_owner.model.dart';
import '../enum/week_day.enum.dart';
import '../model/availability_request.model.dart';
import '../model/user_availability.model.dart';

/// `public.user_availabilities`: Working schedules for accounts and managed bodyguards.
final class AvailabilityRepository {
  final SupabaseClient client;

  AvailabilityRepository(this.client);

  /// Fetches schedule rows for [owner].
  Future<List<UserAvailabilityModel>> getFor(RecordOwner owner) async {
    final rows = await client
        .from(DatabaseTables.userAvailabilities)
        .select()
        .eq(owner.column, owner.id)
        .order(JsonKeys.dayOfWeek);
    return (rows as List<dynamic>)
        .map((r) => UserAvailabilityModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Upserts schedules for [owner] using the unique constraint `(owner_col, day_of_week)`.
  Future<List<UserAvailabilityModel>> save(
    RecordOwner owner,
    List<AvailabilityRequest> requests,
  ) async {
    if (requests.isEmpty) return const [];

    final payload = [for (final req in requests) req.toJson(owner: owner)];

    final rows = await client
        .from(DatabaseTables.userAvailabilities)
        .upsert(payload, onConflict: '${owner.column},${JsonKeys.dayOfWeek}')
        .select();

    return (rows as List<dynamic>)
        .map((r) => UserAvailabilityModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Seeds default schedule (Mon-Fri 09:00 AM - 05:00 PM available, Sat-Sun unavailable).
  Future<void> seedDefaults(RecordOwner owner) async {
    final defaultRequests = [
      for (final day in WeekDay.values)
        AvailabilityRequest(
          dayOfWeek: day,
          isAvailable: day != WeekDay.saturday && day != WeekDay.sunday,
          fromTime: '09:00 AM',
          toTime: '05:00 PM',
        ),
    ];
    await save(owner, defaultRequests);
  }
}
