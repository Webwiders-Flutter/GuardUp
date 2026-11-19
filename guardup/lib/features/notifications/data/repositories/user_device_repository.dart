import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '../models/user_device.model.dart';

/// Repository for managing device tokens in Supabase `public.user_devices`.
/// Extends [BaseSupabaseRepository] to follow consistent data access architecture.
final class UserDeviceRepository
    extends BaseSupabaseRepository<UserDeviceModel> {
  UserDeviceRepository([SupabaseClient? client])
    : super(
        client: client ?? Supabase.instance.client,
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

  /// Registers or updates the device token for the signed-in user via `register_user_device` RPC.
  Future<UserDeviceModel> upsertDevice({
    required String token,
    required String platform,
    String languageCode = 'en',
  }) async {
    final response = await client.rpc(
      DatabaseFunctions.registerUserDevice,
      params: {
        JsonKeys.pToken: token,
        JsonKeys.pPlatform: platform,
        JsonKeys.pLanguageCode: languageCode,
      },
    );

    return fromJson(Map<String, dynamic>.from(response as Map));
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

  /// Updates the push language of this device via `update_user_device_language` RPC.
  Future<UserDeviceModel?> updateLanguage({
    required String token,
    required String languageCode,
  }) async {
    final response = await client.rpc(
      DatabaseFunctions.updateUserDeviceLanguage,
      params: {JsonKeys.pToken: token, JsonKeys.pLanguageCode: languageCode},
    );

    if (response is! Map || response[JsonKeys.id] == null) return null;
    return fromJson(Map<String, dynamic>.from(response));
  }
}
