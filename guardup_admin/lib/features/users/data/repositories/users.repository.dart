import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/user_model.dart';

final class UsersRepository extends BaseSupabaseRepository<UserModel> {
  UsersRepository(SupabaseClient client)
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
    ),
    bank_accounts:user_bank_accounts(
      id,
      user_id,
      account_number,
      account_holder,
      bank_name,
      branch,
      ifsc_code,
      branch_address,
      is_primary,
      created_at,
      updated_at
    ),
    availabilities:user_availabilities(
      id,
      user_id,
      day_of_week,
      is_available,
      from_time,
      to_time,
      created_at,
      updated_at
    )
  ''';

  /// Embedded relations resolve to `[]` when the user has none (services,
  /// documents, bank accounts, availability), so those users load fine.
  /// Bank accounts are visible to admins through the
  /// "Admins can read all bank accounts" RLS policy.
  @override
  Future<UserModel> getDetails(String id) async {
    final response = await client
        .from(tableName)
        .select(_detailsSelect)
        .eq(JsonKeys.id, id)
        // Bank accounts: primary first, then newest first.
        .order(
          JsonKeys.isPrimary,
          referencedTable: JsonKeys.bankAccounts,
          ascending: false,
        )
        .order(
          JsonKeys.createdAt,
          referencedTable: JsonKeys.bankAccounts,
          ascending: false,
        )
        .maybeSingle();

    if (response == null) {
      throw ApiException(
        "Unable to get $entityName details. Please try again later.",
      );
    }

    return UserModel.fromJson(Map<String, dynamic>.from(response));
  }

  // Approving / rejecting an application lives in UserReviewRepository
  // (admin-only RPCs that enforce the review rules).

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

  /// Deletes a user through the delete_user RPC. The database decides how:
  /// never approved (incomplete / pending / rejected) -> removed completely;
  /// otherwise login removed and the profile kept with status DELETED.
  /// See documentation/user_deletion.md.
  @override
  Future<void> delete(String id) async {
    await client.rpc(
      DatabaseFunctions.deleteUser,
      params: {JsonKeys.pUserId: id},
    );
  }
}
