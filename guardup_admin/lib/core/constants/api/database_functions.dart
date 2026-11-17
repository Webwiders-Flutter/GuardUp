/// Postgres RPC names called with `client.rpc(...)`.
final class DatabaseFunctions {
  const DatabaseFunctions._();

  /// Deletes a user (pass [JsonKeys.pUserId]). Deleting a PENDING_APPROVAL
  /// user is how an application is rejected.
  /// See documentation/user_deletion.md.
  static const String deleteUser = 'delete_user';
}
