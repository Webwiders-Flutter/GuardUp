import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/bodyguard.model.dart';

/// Company-managed bodyguards (`public.bodyguards` with `user_id = NULL`) and
/// their verification. See documentation/user_profiles.md.
///
/// Reviews update the rows directly (admins pass RLS); the database triggers
/// own the rules: approve only once every document is approved, a reason to
/// reject, a rejected document rejects the bodyguard, and the company is
/// notified.
final class BodyguardsRepository {
  const BodyguardsRepository(this._client);

  final SupabaseClient _client;

  // Embeds need the FK hint: these tables also reference users, so PostgREST
  // could otherwise reach them from bodyguards through more than one path.
  static const String _select = '''
    *,
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

  /// Bodyguards added by the company [companyId] (`companies.id`), awaiting
  /// review first, then newest first.
  Future<List<BodyguardModel>> getCompanyBodyguards(String companyId) async {
    final rows = await _client
        .from(DatabaseTables.bodyguards)
        .select(_select)
        .eq(JsonKeys.companyId, companyId)
        .isFilter(JsonKeys.userId, null)
        .order(JsonKeys.createdAt, ascending: false);

    final bodyguards = rows.map(BodyguardModel.fromJson).toList();
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

  /// Blocks (suspends) or unblocks an approved bodyguard.
  Future<void> setBlocked(String bodyguardId, {required bool blocked}) =>
      _update(bodyguardId, {
        JsonKeys.registrationStatus:
            (blocked ? UserStatus.blocked : UserStatus.active).apiValue,
      });

  Future<void> _update(String bodyguardId, Map<String, dynamic> data) async {
    final rows = await _client
        .from(DatabaseTables.bodyguards)
        .update(data)
        .eq(JsonKeys.id, bodyguardId)
        .select(JsonKeys.id);
    if (rows.isEmpty) {
      throw ApiException('Bodyguard not found. It may have been removed.');
    }
  }
}
