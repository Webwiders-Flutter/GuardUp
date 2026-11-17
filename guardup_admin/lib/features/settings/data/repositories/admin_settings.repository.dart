import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../models/admin_settings.model.dart';

/// Repository for platform-level administrative settings.
///
/// Interfaces with the singleton `admin_settings` Supabase table.
class AdminSettingsRepository {
  final SupabaseClient _client;

  const AdminSettingsRepository(this._client);

  /// Retrieves the current admin settings singleton record.
  ///
  /// If no row exists yet in `admin_settings`, automatically bootstraps
  /// a default configuration record.
  Future<AdminSettingsModel> getSettings() async {
    return asyncHandler(() async {
      final response = await _client
          .from(DatabaseTables.adminSettings)
          .select()
          .maybeSingle();

      if (response != null) {
        return AdminSettingsModel.fromJson(response);
      }

      // Automatically bootstrap initial row if empty
      try {
        final inserted = await _client
            .from(DatabaseTables.adminSettings)
            .insert({JsonKeys.singletonGuard: true})
            .select()
            .maybeSingle();

        if (inserted != null) {
          return AdminSettingsModel.fromJson(inserted);
        }
      } catch (_) {
        // Fallback to default in-memory model if insert permission is restricted
      }

      return AdminSettingsModel.initial();
    });
  }

  /// Updates admin settings.
  ///
  /// Safely upserts by singleton_guard unique constraint and returns
  /// the freshly updated [AdminSettingsModel].
  Future<AdminSettingsModel> updateSettings(Map<String, dynamic> data) async {
    return asyncHandler(() async {
      final payload = Map<String, dynamic>.from(data)
        ..remove(JsonKeys.id)
        ..remove(JsonKeys.createdAt)
        ..remove(JsonKeys.updatedAt);

      payload[JsonKeys.singletonGuard] = true;

      final response = await _client
          .from(DatabaseTables.adminSettings)
          .upsert(payload, onConflict: JsonKeys.singletonGuard)
          .select()
          .maybeSingle();

      if (response == null) {
        throw ApiException(
          'Failed to update system settings. Please try again.',
        );
      }

      return AdminSettingsModel.fromJson(response);
    });
  }
}
