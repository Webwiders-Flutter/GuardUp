import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/repositories/base.repository.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/bodyguard.model.dart';

/// Company-managed bodyguards (`public.bodyguards` with `user_id = NULL`):
/// the admin listing per status, one bodyguard's details, and its review.
/// See documentation/user_profiles.md.
///
/// Reviews update the rows directly (admins pass RLS); the database triggers
/// own the rules, exactly as for accounts: approve only once every document
/// is approved, a reason to reject, a rejected document rejects the
/// bodyguard, and the company is notified (also when an admin deletes it).
final class CompanyBodyguardsRepository
    extends BaseSupabaseRepository<BodyguardModel> {
  CompanyBodyguardsRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.bodyguards,
        fromJson: BodyguardModel.fromJson,
        entityName: 'bodyguard',
        searchFields: const [JsonKeys.name],
        selectColumns: _listSelect,
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  /// The managing company, with the FK named so the embed stays unambiguous.
  static const String _companySelect =
      'company:companies!bodyguards_company_id_fkey(id, user_id, company_name, company_phone_code, company_phone_number)';

  /// Lightweight select for the listing: the row plus its company name.
  static const String _listSelect = '*, $_companySelect';

  // Embeds need the FK hint: these tables also reference users, so PostgREST
  // could otherwise reach them from bodyguards through more than one path.
  static const String _detailsSelect =
      '''
    *,
    $_companySelect,
    services:user_services!user_services_bodyguard_id_fkey(
      id,
      service:services(id, name, description, icon_name, is_active, display_order)
    ),
    documents:user_documents!user_documents_bodyguard_id_fkey(
      id,
      user_id,
      bodyguard_id,
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
    availabilities:user_availabilities!user_availabilities_bodyguard_id_fkey(
      id,
      user_id,
      bodyguard_id,
      day_of_week,
      is_available,
      from_time,
      to_time,
      created_at,
      updated_at
    )
  ''';

  /// Name query filter.
  @override
  String? buildSearchFilter(String queryStr) {
    final raw = queryStr.trim().replaceAll('"', '');
    if (raw.isEmpty) return null;

    return '${JsonKeys.name}.ilike."%$raw%"';
  }

  /// Company-managed bodyguards with [status], newest first.
  @override
  Future<({List<BodyguardModel> data, int total})> getPaginated({
    required int page,
    required int pageSize,
    UserStatus? status,
    bool? isActive,
    String? search,
    CustomQueryBuilder? customQuery,
  }) {
    return super.getPaginated(
      page: page,
      pageSize: pageSize,
      search: search,
      customQuery: (query) {
        query = query.isFilter(JsonKeys.userId, null);
        if (status != null) {
          query = query.eq(JsonKeys.registrationStatus, status.apiValue);
        }
        return customQuery?.call(query) ?? query;
      },
    );
  }

  /// One company-managed bodyguard with its company, services, documents and
  /// availability.
  @override
  Future<BodyguardModel> getDetails(String id) async {
    final row = await client
        .from(tableName)
        .select(_detailsSelect)
        .eq(JsonKeys.id, id)
        .isFilter(JsonKeys.userId, null)
        .maybeSingle();
    if (row == null) {
      throw ApiException('Bodyguard not found. It may have been removed.');
    }
    return fromJson(row);
  }

  /// Bodyguards added by the company [companyId] (`companies.id`), awaiting
  /// review first, then newest first.
  Future<List<BodyguardModel>> getCompanyBodyguards(String companyId) async {
    final rows = await client
        .from(tableName)
        .select(_detailsSelect)
        .eq(JsonKeys.companyId, companyId)
        .isFilter(JsonKeys.userId, null)
        .order(JsonKeys.createdAt, ascending: false);

    final bodyguards = rows.map(fromJson).toList();
    // Stable sort keeps newest-first inside each group.
    bodyguards.sort(
      (a, b) => _reviewRank(a.status).compareTo(_reviewRank(b.status)),
    );
    return bodyguards;
  }

  static int _reviewRank(UserStatus status) => switch (status) {
    UserStatus.approvalPending => 0,
    UserStatus.rejected => 1,
    _ => 2,
  };

  /// Approves the bodyguard (ACTIVE). Fails unless every document is approved.
  Future<void> approve(String bodyguardId) => _update(bodyguardId, {
    JsonKeys.registrationStatus: UserStatus.active.apiValue,
  });

  /// Rejects the bodyguard (REJECTED) with [reason]; the company is notified.
  Future<void> reject(String bodyguardId, String reason) =>
      _update(bodyguardId, {
        JsonKeys.registrationStatus: UserStatus.rejected.apiValue,
        JsonKeys.rejectionReason: reason,
      });

  /// Removes the bodyguard; its services, documents and availability go with
  /// it (ON DELETE CASCADE) and the company is notified.
  @override
  Future<void> delete(String id) async {
    final rows = await client
        .from(tableName)
        .delete()
        .eq(JsonKeys.id, id)
        .isFilter(JsonKeys.userId, null)
        .select(JsonKeys.id);
    if (rows.isEmpty) {
      throw ApiException('Bodyguard not found. It may have been removed.');
    }
  }

  /// Only status changes go through this repository ([approve], [reject]);
  /// the company edits the profile in the app. Company bodyguards are never
  /// blocked: an admin approves, rejects or deletes them.
  @override
  Future<BodyguardModel> addOrUpdate(
    Map<String, dynamic> data, {
    String? id,
  }) => throw UnsupportedError('Bodyguards are edited by their company.');

  Future<void> _update(String bodyguardId, Map<String, dynamic> data) async {
    final rows = await client
        .from(tableName)
        .update(data)
        .eq(JsonKeys.id, bodyguardId)
        .select(JsonKeys.id);
    if (rows.isEmpty) {
      throw ApiException('Bodyguard not found. It may have been removed.');
    }
  }
}
