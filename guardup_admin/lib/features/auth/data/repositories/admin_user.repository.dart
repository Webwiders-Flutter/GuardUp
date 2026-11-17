import '/core/error/api_exception.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/models/user_model.dart';
import '/core/constants/api/database_tables.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserRepository {
  const AdminUserRepository(this._client);

  final SupabaseClient _client;

  Future<UserModel?> updateProfile(Map<String, dynamic> data) async {
    final currentUserId = _client.auth.currentUser?.id;
    final query = _client.from(DatabaseTables.users).update(data);
    final dynamic filteredQuery = currentUserId != null
        ? query.eq('id', currentUserId)
        : query.eq('role', UserRoleType.admin.apiValue);
    final result = await filteredQuery.select().limit(1);
    if (result.isEmpty) {
      throw ApiException("Unable to update profile. Please try again later.");
    }
    return UserModel.fromJson(result.first);
  }

  Future<UserModel?> getProfile() async {
    final currentUserId = _client.auth.currentUser?.id;
    final query = _client.from(DatabaseTables.users).select();
    final dynamic filteredQuery = currentUserId != null
        ? query.eq('id', currentUserId)
        : query.eq('user_role', UserRoleType.admin.apiValue);
    final result = await filteredQuery.limit(1);

    if (result.isEmpty) {
      throw ApiException("Unable to get profile. Please try again later.");
    }

    return UserModel.fromJson(result.first);
  }
}
