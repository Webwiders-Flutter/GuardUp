import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '../model/company.model.dart';
import '../model/company_filters.model.dart';
import '../model/company_profile_request.model.dart';

/// Repository for querying security company profiles (`public.companies`).
final class CompanyRepository extends BaseSupabaseRepository<CompanyModel> {
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

  static const String _selectColumns = '''
    *,
    user:users!companies_user_id_fkey(
      id,
      name,
      status,
      profile_image_url
    )
  ''';

  static const String _selectColumnsActiveOnly = '''
    *,
    user:users!companies_user_id_fkey!inner(
      id,
      name,
      status,
      profile_image_url
    )
  ''';

  @override
  Future<({List<CompanyModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    bool? isActive,
    String? search,
    String? selectColumnsOverride,
    UserStatus? status,
    List<UserStatus>? statuses,
    CompanyFilters? filters,
    CustomQueryBuilder? customQuery,
  }) {
    final effectiveStatuses = filters?.statuses ?? statuses;

    // When filtering by active user status, use the !inner join so pagination counts stay exact
    final selectQuery =
        (status != null ||
            (effectiveStatuses != null && effectiveStatuses.isNotEmpty))
        ? _selectColumnsActiveOnly
        : (selectColumnsOverride ?? _selectColumns);

    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
      search: search,
      selectColumnsOverride: selectQuery,
      customQuery: (query) {
        if (customQuery != null) {
          query = customQuery(query);
        }

        if (effectiveStatuses != null && effectiveStatuses.isNotEmpty) {
          final values = effectiveStatuses.map((s) => s.apiValue).toList();
          query = query.inFilter('user.status', values);
        } else if (status != null) {
          query = query.eq('user.status', status.apiValue);
        }

        return query;
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
