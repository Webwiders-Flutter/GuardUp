/// Postgres RPC names called with `client.rpc(...)`.
final class DatabaseFunctions {
  const DatabaseFunctions._();

  /// Deletes a user (pass [JsonKeys.pUserId]). Deleting a PENDING_APPROVAL
  /// user is how an application is rejected.
  /// See documentation/user_deletion.md.
  static const String deleteUser = 'delete_user';

  /// Creates or updates the caller's device row, keyed on the FCM token
  /// (pass [JsonKeys.pToken], [JsonKeys.pPlatform], [JsonKeys.pLanguageCode]).
  /// See documentation/notifications_and_user_lifecycle.md.
  static const String registerUserDevice = 'register_user_device';

  /// Changes the push language of one of the caller's devices
  /// (pass [JsonKeys.pToken], [JsonKeys.pLanguageCode]).
  static const String updateUserDeviceLanguage = 'update_user_device_language';
}
