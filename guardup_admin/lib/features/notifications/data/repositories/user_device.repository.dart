import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
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

  /// Registers the device token for the signed-in user (register_user_device).
  ///
  /// New token -> new row. Known token -> moved to the signed-in user,
  /// re-activated and its language updated. Each token keeps its own
  /// language, so two devices can use different languages.
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

  /// Updates the push language of this token only (update_user_device_language).
  /// Returns null when the token is not registered for the signed-in user.
  Future<UserDeviceModel?> updateLanguage({
    required String token,
    required String languageCode,
  }) async {
    final response = await client.rpc(
      DatabaseFunctions.updateUserDeviceLanguage,
      params: {
        JsonKeys.pToken: token,
        JsonKeys.pLanguageCode: languageCode,
      },
    );

    // A NULL composite comes back as null or as a map of nulls.
    if (response is! Map || response[JsonKeys.id] == null) return null;
    return fromJson(Map<String, dynamic>.from(response));
  }
}
