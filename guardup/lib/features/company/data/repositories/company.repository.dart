import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '../model/company.model.dart';
import '../model/company_filters.model.dart';
import '../model/company_profile_request.model.dart';

/// Repository for querying security company profiles (`public.companies`).
class CompanyRepository extends BaseSupabaseRepository<CompanyModel> {
  CompanyRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.companies,
        fromJson: CompanyModel.fromJson,
        entityName: 'company',
        searchFields: const [JsonKeys.companyName],
        selectColumns: _selectColumns,
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  /// `account_status` is a computed field (users.status of the company
  /// account). The `user` embed is a plain left join: `users` is readable only
  /// by its owner and admins, so it is `null` for everyone else and must never
  /// be `!inner` (that removed every company from the customer list).
  ///
  /// Note: [getPaginated] uses this lean select columns string WITHOUT documents.
  static const String _selectColumns =
      '''
    *,
    ${JsonKeys.accountStatus},
    user:users!companies_user_id_fkey(
      id,
      name,
      status,
      profile_image_url
    )
  ''';

  /// Detailed select columns used strictly for company detail views.
  /// Documents are embedded via [DatabaseFunctions.listingDocuments].
  static const String _detailsSelectColumns =
      '''
    *,
    ${JsonKeys.accountStatus},
    user:users!companies_user_id_fkey(
      id,
      name,
      status,
      profile_image_url
    ),
    documents:${DatabaseFunctions.listingDocuments}(
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

  /// One company profile with its account status, user summary, and verified documents.
  ///
  /// Documents are joined ONLY on this detail query, never in [getPaginated].
  @override
  Future<CompanyModel> getDetails(String id) async {
    final row = await client
        .from(tableName)
        .select(_detailsSelectColumns)
        .eq(JsonKeys.id, id)
        .maybeSingle();

    if (row == null) {
      throw ApiException('Company not found. It may have been removed.');
    }

    return fromJson(row);
  }

  /// One page of companies matching [filters].
  @override
  Future<({List<CompanyModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    String? search,
    String? selectColumnsOverride,
    CompanyFilters filters = const CompanyFilters(),
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
      search: search,
      selectColumnsOverride: selectColumnsOverride,
      customQuery: (query) {
        final statuses = filters.statuses;
        if (statuses != null && statuses.isNotEmpty) {
          query = query.inFilter(
            JsonKeys.accountStatus,
            statuses.map((s) => s.apiValue).toList(),
          );
        }
        return customQuery?.call(query) ?? query;
      },
    );
  }

  /// Upserts company details on `user_id`.
  Future<void> upsertForAccount(
    String userId,
    CompanyProfileRequest request,
  ) async {
    await client.from(tableName).upsert({
      JsonKeys.userId: userId,
      ...request.toJson(),
    }, onConflict: JsonKeys.userId);
  }

  /// Fetches company profile by account [userId].
  Future<CompanyModel?> getByUserId(String userId) async {
    final row = await client
        .from(tableName)
        .select(_selectColumns)
        .eq(JsonKeys.userId, userId)
        .maybeSingle();
    return row != null ? fromJson(row) : null;
  }
}
