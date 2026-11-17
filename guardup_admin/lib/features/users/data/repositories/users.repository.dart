import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/enums/verification_status.enum.dart';
import '/features/users/data/models/user_model.dart';

final class UsersRepository extends BaseSupabaseRepository<UserModel> {
  final FunctionsClient _function;

  UsersRepository(SupabaseClient client, this._function)
    : super(
        client: client,
        tableName: DatabaseTables.users,
        fromJson: UserModel.fromJson,
        entityName: 'user',
        searchFields: const [
          JsonKeys.fullName,
          JsonKeys.email,
          JsonKeys.mobileNumber,
          JsonKeys.businessName,
        ],
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  @override
  Future<({List<UserModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    UserRoleType? role,
    UserStatus? status,
    String? search,
    bool? isActive,
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      search: search,
      customQuery: (query) {
        if (status != null) {
          query = query.eq(JsonKeys.registrationStatus, status.apiValue);
        } else {
          query = query
              .neq(JsonKeys.registrationStatus, UserStatus.incomplete.apiValue)
              .neq(JsonKeys.registrationStatus, UserStatus.deleted.apiValue);
        }
        if (role != null) {
          query = query.eq(JsonKeys.role, role.apiValue);
        }
        if (customQuery != null) {
          query = customQuery(query);
        }
        return query;
      },
    );
  }

  static const String _detailsSelect = '''
    *,
    user_services(
      id,
      service:services(id, name, description, icon_name, is_active, display_order)
    ),
    documents:user_documents(
      id,
      user_id,
      document_type_id,
      file_url,
      file_name,
      status,
      rejection_reason,
      valid_till,
      uploaded_at,
      updated_at,
      document_type:document_types(
        id, name, description, target_role, is_required, is_active, display_order
      )
    )
  ''';

  /// Embedded relations resolve to `[]` when the user has no services or
  /// documents, so those users load fine.
  @override
  Future<UserModel> getDetails(String id) async {
    final response = await client
        .from(tableName)
        .select(_detailsSelect)
        .eq(JsonKeys.id, id)
        .maybeSingle();

    if (response == null) {
      throw ApiException(
        "Unable to get $entityName details. Please try again later.",
      );
    }

    return UserModel.fromJson(Map<String, dynamic>.from(response));
  }

  /// Approves user application and marks pending documents as verified.
  Future<UserModel> markVerified(String id) async {
    // 1. Update user registration status to active/approved
    await client
        .from(tableName)
        .update({JsonKeys.registrationStatus: UserStatus.active.apiValue})
        .eq(JsonKeys.id, id);

    // 2. Update user documents to approved
    try {
      await client
          .from(DatabaseTables.userDocuments)
          .update({JsonKeys.status: VerificationStatus.verified.apiValue})
          .eq(JsonKeys.userId, id);
    } catch (_) {}

    return getDetails(id);
  }

  /// Rejects user registration.
  Future<UserModel> rejectUser(String id) async {
    await client
        .from(tableName)
        .update({JsonKeys.registrationStatus: UserStatus.rejected.apiValue})
        .eq(JsonKeys.id, id);

    try {
      await client
          .from(DatabaseTables.userDocuments)
          .update({JsonKeys.status: VerificationStatus.rejected.apiValue})
          .eq(JsonKeys.userId, id);
    } catch (_) {}

    return getDetails(id);
  }

  /// Blocks user account.
  Future<UserModel> blockUser(String id) async {
    await client
        .from(tableName)
        .update({JsonKeys.registrationStatus: UserStatus.blocked.apiValue})
        .eq(JsonKeys.id, id);

    return getDetails(id);
  }

  /// Unblocks user account to approved status.
  Future<UserModel> unblockUser(String id) async {
    await client
        .from(tableName)
        .update({JsonKeys.registrationStatus: UserStatus.active.apiValue})
        .eq(JsonKeys.id, id);

    return getDetails(id);
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _function.invoke('delete-user', body: {JsonKeys.userIdParam: id});
    } catch (_) {}
    // Update user status to DELETED (triggers on_user_status_deleted in DB)
    await client
        .from(tableName)
        .update({JsonKeys.registrationStatus: UserStatus.deleted.apiValue})
        .eq(JsonKeys.id, id);
  }
}
