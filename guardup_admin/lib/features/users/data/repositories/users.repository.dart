import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/enums/verification_status.enum.dart';
import '/features/users/data/models/user_document.model.dart';
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

  @override
  Future<UserModel> getDetails(String id) async {
    final response = await client
        .from(tableName)
        .select('*')
        .eq(JsonKeys.id, id)
        .maybeSingle();

    if (response == null) {
      throw ApiException(
        "Unable to get $entityName details. Please try again later.",
      );
    }

    // Load related user documents from documents table
    List<UserDocumentModel> userDocs = [];
    try {
      final docsRes = await client
          .from(DatabaseTables.userDocuments)
          .select()
          .eq('user_id', id);

      for (final d in docsRes) {
        final map = d;
        final docStatusStr = (map['status'] as String? ?? '').toUpperCase();
        final vStatus = docStatusStr == 'APPROVED' || docStatusStr == 'VERIFIED'
            ? VerificationStatus.verified
            : (docStatusStr == 'REJECTED'
                ? VerificationStatus.rejected
                : VerificationStatus.pending);

        userDocs.add(
          UserDocumentModel(
            id: (map['id'] ?? '') as String,
            userId: (map['user_id'] ?? id) as String,
            documentTypeId: map['document_type_id'] as String?,
            documentTypeName: map['document_type_name'] as String?,
            fileUrl: (map['file_url'] ?? '') as String,
            fileName: map['file_name'] as String?,
            verificationStatus: vStatus,
            rejectionReason: map['rejection_reason'] as String?,
            createdAt: map['created_at'] != null
                ? DateTime.tryParse(map['created_at'].toString())
                : null,
            updatedAt: map['updated_at'] != null
                ? DateTime.tryParse(map['updated_at'].toString())
                : null,
          ),
        );
      }
    } catch (_) {}

    final user = UserModel.fromJson(response);
    return user.copyWith(documents: userDocs);
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
          .update({'status': 'APPROVED'})
          .eq('user_id', id);
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
          .update({'status': 'REJECTED'})
          .eq('user_id', id);
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
