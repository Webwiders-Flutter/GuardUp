import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '/features/notifications/data/models/user_device.model.dart';

/// Repository for managing device tokens in Supabase `public.user_devices`.
/// Extends [BaseSupabaseRepository] to follow consistent data access architecture.
final class UserDeviceRepository
    extends BaseSupabaseRepository<UserDeviceModel> {
  UserDeviceRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.userDevices,
        fromJson: UserDeviceModel.fromJson,
        entityName: 'user device',
        searchFields: const [
          JsonKeys.token,
          JsonKeys.platform,
          JsonKeys.languageCode,
        ],
        primarySortColumn: JsonKeys.lastActiveAt,
        primarySortAscending: false,
      );

  /// Registers or updates the device token in Supabase on conflict of 'token'.
  Future<UserDeviceModel> upsertDevice({
    required String userId,
    required String token,
    required String platform,
    String languageCode = 'en',
  }) async {
    final payload = {
      JsonKeys.userId: userId,
      JsonKeys.token: token,
      JsonKeys.platform: platform,
      JsonKeys.languageCode: languageCode,
      JsonKeys.isActive: true,
      JsonKeys.lastActiveAt: DateTime.now().toIso8601String(),
    };

    final response = await client
        .from(tableName)
        .upsert(payload, onConflict: 'token')
        .select()
        .single();

    return fromJson(response);
  }

  /// Deactivates a device token upon user sign-out so notifications stop being delivered.
  Future<void> deactivateDevice(String token) async {
    await client
        .from(tableName)
        .update({
          JsonKeys.isActive: false,
          JsonKeys.lastActiveAt: DateTime.now().toIso8601String(),
        })
        .eq(JsonKeys.token, token);
  }

  /// Removes the device token row completely from `public.user_devices`.
  Future<void> deleteByToken(String token) async {
    await client.from(tableName).delete().eq(JsonKeys.token, token);
  }

  /// Updates the device's preferred language for notifications.
  Future<void> updateLanguage({
    required String token,
    required String languageCode,
  }) async {
    await client
        .from(tableName)
        .update({
          JsonKeys.languageCode: languageCode,
          JsonKeys.lastActiveAt: DateTime.now().toIso8601String(),
        })
        .eq(JsonKeys.token, token);
  }
}
