import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/logger/supabase_logger.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/features/auth/data/model/user.model.dart';
import '../model/body_guard.model.dart';

/// Bodyguards managed by the signed-in company (`public.bodyguards` rows with
/// `user_id = NULL` and `company_id` = the caller's company).
///
/// Self-registered bodyguards (GUARD accounts) keep using [UserRepository]:
/// their profile is read from `user_profiles` and written through
/// `updateProfileFields`. Their child rows (services, documents,
/// availability) are keyed by `user_id`; company-managed ones by
/// `bodyguard_id`. See documentation/user_profiles.md.
class BodyguardRepository {
  final SupabaseClient? _client;

  BodyguardRepository([this._client]);

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String get _currentUserId {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw ApiException('Your session has expired. Please sign in again.');
    }
    return uid;
  }

  /// The `companies.id` of the signed-in COMPANY account.
  Future<String> getMyCompanyId() async {
    final row = await _supabase
        .from(DatabaseTables.companies)
        .select(JsonKeys.id)
        .eq(JsonKeys.userId, _currentUserId)
        .maybeSingle();

    final id = row?[JsonKeys.id] as String?;
    if (id == null || id.isEmpty) {
      throw ApiException('Company profile not found. Please complete your company profile.');
    }
    return id;
  }

  /// One page of the company's bodyguards, newest first.
  Future<({List<BodyGuardModel> data, int total})> getCompanyBodyguards({
    required int page,
    required int pageSize,
    String? search,
  }) async {
    final companyId = await getMyCompanyId();

    var query = _supabase
        .from(DatabaseTables.bodyguards)
        .select()
        .eq(JsonKeys.companyId, companyId)
        .isFilter(JsonKeys.userId, null);

    final term = search?.trim().replaceAll(RegExp(r'[%,()"]'), '') ?? '';
    if (term.isNotEmpty) {
      query = query.ilike(JsonKeys.name, '%$term%');
    }

    final response = await query
        .order(JsonKeys.createdAt, ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1)
        .count(CountOption.exact);

    final rows = response.data;
    return (
      data: rows.map(_toModel).toList(),
      total: response.count,
    );
  }

  /// A single bodyguard row the caller can read, or `null`.
  Future<BodyGuardModel?> getBodyguard(String bodyguardId) async {
    final row = await _supabase
        .from(DatabaseTables.bodyguards)
        .select()
        .eq(JsonKeys.id, bodyguardId)
        .maybeSingle();
    return row == null ? null : _toModel(row);
  }

  /// Creates ([bodyguardId] null) or updates a company-managed bodyguard.
  Future<BodyGuardModel> saveCompanyBodyguard({
    String? bodyguardId,
    required String name,
    required double hourlyRate,
    required String bio,
    String? profileImageUrl,
  }) async {
    final payload = <String, dynamic>{
      JsonKeys.name: name,
      JsonKeys.hourlyRate: hourlyRate,
      JsonKeys.bio: bio,
      JsonKeys.profileImageUrl: ?profileImageUrl,
    };

    SupabaseLogger.request(
      'saveCompanyBodyguard',
      payload: {JsonKeys.id: bodyguardId, ...payload},
    );

    final Map<String, dynamic> row;
    if (bodyguardId == null) {
      row = await _supabase
          .from(DatabaseTables.bodyguards)
          .insert({JsonKeys.companyId: await getMyCompanyId(), ...payload})
          .select()
          .single();
    } else {
      final rows = await _supabase
          .from(DatabaseTables.bodyguards)
          .update(payload)
          .eq(JsonKeys.id, bodyguardId)
          .select();
      if (rows.isEmpty) {
        throw ApiException('This bodyguard could not be updated. It may have been removed.');
      }
      row = rows.first;
    }

    SupabaseLogger.success('saveCompanyBodyguard', result: 'id=${row[JsonKeys.id]}');
    return _toModel(row);
  }

  /// Removes a company-managed bodyguard. Its services, documents and
  /// availability are removed with it (ON DELETE CASCADE).
  Future<void> deleteCompanyBodyguard(String bodyguardId) async {
    final rows = await _supabase
        .from(DatabaseTables.bodyguards)
        .delete()
        .eq(JsonKeys.id, bodyguardId)
        .select(JsonKeys.id);
    if (rows.isEmpty) {
      throw ApiException('This bodyguard could not be removed.');
    }
  }

  /// Sends a company-managed bodyguard to admin review (INCOMPLETE /
  /// REJECTED -> PENDING_APPROVAL). Does nothing in any other state, e.g. an
  /// already approved bodyguard, or one a re-uploaded document already moved
  /// back to review.
  Future<void> submitForReview(String bodyguardId) async {
    await _supabase
        .from(DatabaseTables.bodyguards)
        .update({JsonKeys.status: UserStatus.pendingApproval.apiValue})
        .eq(JsonKeys.id, bodyguardId)
        .inFilter(JsonKeys.status, [
          UserStatus.incomplete.apiValue,
          UserStatus.rejected.apiValue,
        ]);
  }

  /// Service ids of a company-managed bodyguard.
  Future<List<String>> getServiceIds(String bodyguardId) async {
    final rows = await _supabase
        .from(DatabaseTables.userServices)
        .select(JsonKeys.serviceId)
        .eq(JsonKeys.bodyguardId, bodyguardId);
    return rows
        .map((r) => r[JsonKeys.serviceId]?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Replaces the services of a company-managed bodyguard atomically.
  Future<void> setServices(String bodyguardId, List<String> serviceIds) {
    return _supabase.rpc(
      DatabaseFunctions.setBodyguardServices,
      params: {
        JsonKeys.pBodyguardId: bodyguardId,
        JsonKeys.pServiceIds: serviceIds,
      },
    );
  }

  /// Maps a `bodyguards` row to the UI model. A company-managed bodyguard has
  /// no login, so its [UserModel.id] is empty.
  BodyGuardModel _toModel(Map<String, dynamic> row) {
    final imageUrl = (row[JsonKeys.profileImageUrl] as String?)?.trim();
    return BodyGuardModel(
      id: row[JsonKeys.id] as String,
      user: UserModel(
        id: (row[JsonKeys.userId] as String?) ?? '',
        name: (row[JsonKeys.name] as String?) ?? '',
        profileImageUrl: (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
        role: UserRole.guard,
      ),
      hourlyRate: _toDouble(row[JsonKeys.hourlyRate]),
      bio: (row[JsonKeys.bio] as String?) ?? '',
      experienceYears: _toDouble(row[JsonKeys.experienceYears]).toInt(),
      rating: _toDouble(row[JsonKeys.rating]),
      verificationStatus: UserStatus.fromApiValue(row[JsonKeys.status] as String?),
      rejectionReason: (row[JsonKeys.rejectionReason] as String?)?.trim(),
    );
  }

  static double _toDouble(Object? value) => switch (value) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}
