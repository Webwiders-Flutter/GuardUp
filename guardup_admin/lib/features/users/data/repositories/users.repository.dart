import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_functions.dart';
import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/error/api_exception.dart';
import '/core/extensions/string.extension.dart';
import '/core/repositories/base.repository.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/data/models/user_model.dart';

/// Lists and searches accounts directly through the `users` table and
/// writes account fields to `users`. Role-specific profile rows are embedded
/// via PostgREST relations. See documentation/user_profiles.md.
final class UsersRepository extends BaseSupabaseRepository<UserModel> {
  UsersRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.users,
        fromJson: (json) => UserModel.fromJson(_normalizeProfiles(json)),
        entityName: 'user',
        // Only columns that live on `users`; company/bodyguard columns are
        // accessed via the embedded relation select below, not searched here.
        searchFields: const [
          JsonKeys.fullName,
          JsonKeys.email,
          JsonKeys.mobileNumber,
          JsonKeys.phoneCode,
        ],
        // Embed company and bodyguard for every list row so UserModel.fromJson
        // can populate the nested company/bodyguard fields.
        selectColumns: _listSelect,
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  /// Lightweight select for list / paginated queries.
  ///
  /// - `company`: only `company_name` — the list shows it as the display name
  ///   for COMPANY accounts; all other company fields are loaded via [getDetails].
  /// - `bodyguard`: not needed on the list — guards are shown by their `users.name`.
  static const String _listSelect =
      '*, company:companies!companies_user_id_fkey(id, user_id, company_name)';

  @override
  String? buildSearchFilter(String queryStr) {
    final raw = queryStr.trim();
    if (raw.isEmpty) return null;

    final sanitizedRaw = raw.replaceAll('"', '');
    final filters = <String>{};

    // 1. Core account text fields (columns on `users` only)
    filters.add('${JsonKeys.fullName}.ilike."%$sanitizedRaw%"');
    filters.add('${JsonKeys.email}.ilike."%$sanitizedRaw%"');

    // 2. Phone Number & Phone Code analysis
    final cleanDigits = raw.replaceAll(RegExp(r'\D'), '');
    final startsWithPlus = raw.startsWith('+');

    void addPhoneFilter(String phoneCodeDigits, String phoneNumberDigits) {
      if (phoneNumberDigits.isEmpty) return;

      // Match user phone with code + number
      filters.add(
        'and(${JsonKeys.phoneCode}.ilike."%$phoneCodeDigits%",${JsonKeys.mobileNumber}.ilike."%$phoneNumberDigits%")',
      );
      // Also match national phone number directly
      filters.add('${JsonKeys.mobileNumber}.ilike."%$phoneNumberDigits%"');
    }

    // A. Query is solely '+' or dial code (e.g. "+", "+91", "+1", "+44")
    if (raw == '+') {
      filters.add('${JsonKeys.phoneCode}.ilike."%+%"');
    } else if (RegExp(r'^\+\d{1,4}$').hasMatch(raw)) {
      final codeDigits = cleanDigits;
      filters.add('${JsonKeys.phoneCode}.ilike."%+$codeDigits%"');
      filters.add('${JsonKeys.phoneCode}.ilike."%$codeDigits%"');
    }

    // B. Query has phone code + phone number separated by space, hyphen, brackets, etc.
    // e.g. "+91 9876543210", "+91-9876543210", "91 9876543210", "+1 (555) 123-4567"
    final splitBySeparatorMatch = RegExp(r'^\+?(\d{1,4})[\s\-./()]+(\d.*)$')
        .firstMatch(raw);
    if (splitBySeparatorMatch != null) {
      final codeDigits = splitBySeparatorMatch.group(1)!;
      final numberPart = splitBySeparatorMatch
          .group(2)!
          .replaceAll(RegExp(r'\D'), '');
      addPhoneFilter(codeDigits, numberPart);
    }

    // C. Query starts with '+' without separator (e.g. "+919876543210" or "+919876")
    if (startsWithPlus && cleanDigits.length > 1) {
      // 1. Try E.164 library parser
      final parsed = raw.parseE164Phone();
      if (parsed.phoneCode.isNotEmpty && parsed.phoneNumber.isNotEmpty) {
        final codeDigits = parsed.phoneCode.replaceAll(RegExp(r'\D'), '');
        addPhoneFilter(codeDigits, parsed.phoneNumber);
      }

      // 2. Default/common +91 check
      if (cleanDigits.startsWith('91') && cleanDigits.length > 2) {
        addPhoneFilter('91', cleanDigits.substring(2));
      }

      // 3. Fallback check for 1-4 digit country codes
      for (final len in [1, 2, 3, 4]) {
        if (cleanDigits.length > len) {
          final prefix = cleanDigits.substring(0, len);
          final rest = cleanDigits.substring(len);
          if (rest.length >= 3) {
            addPhoneFilter(prefix, rest);
          }
        }
      }
    }

    // D. Digits without leading '+' (e.g. "9876543210", "919876543210", "98765")
    if (cleanDigits.isNotEmpty) {
      filters.add('${JsonKeys.mobileNumber}.ilike."%$cleanDigits%"');

      // If starts with 91 and length > 10 (e.g. 12-digit Indian number without '+')
      if (cleanDigits.length > 10 && cleanDigits.startsWith('91')) {
        addPhoneFilter('91', cleanDigits.substring(2));
      }
    }

    // E. General fallback for the raw sanitized string against phone fields
    if (sanitizedRaw.isNotEmpty) {
      filters.add('${JsonKeys.mobileNumber}.ilike."%$sanitizedRaw%"');
    }

    return filters.isNotEmpty ? filters.join(',') : null;
  }

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

  // companies / bodyguards need the FK hint: user_services, user_documents
  // and user_availabilities also link users to bodyguards (and bodyguards
  // link users to companies), so PostgREST would see several relationships.
  static const String _detailsSelect = '''
    *,
    company:companies!companies_user_id_fkey(
      id, user_id, company_name, business_email, company_type,
      company_phone_code, company_phone_number, experience_years,
      created_at, updated_at
    ),
    bodyguard:bodyguards!bodyguards_user_id_fkey(
      id, user_id, company_id, name, profile_image_url, address,
      latitude, longitude, hourly_rate, rating, experience_years,
      bio, languages, certifications, is_active, status, rejection_reason,
      created_at, updated_at
    ),
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
        .from(DatabaseTables.users)
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

    return UserModel.fromJson(_normalizeProfiles(response));
  }

  /// `company` / `bodyguard` are one-to-one embeds: an object, or a one-item
  /// list on older PostgREST versions. [UserModel] expects an object or null.
  static Map<String, dynamic> _normalizeProfiles(Map<String, dynamic> row) {
    return Map<String, dynamic>.from(row)
      ..[JsonKeys.company] = _singleEmbed(row[JsonKeys.company])
      ..[JsonKeys.bodyguard] = _singleEmbed(row[JsonKeys.bodyguard]);
  }

  static Map<String, dynamic>? _singleEmbed(Object? value) => switch (value) {
    Map<String, dynamic> map => map,
    List<dynamic> list
        when list.isNotEmpty && list.first is Map<String, dynamic> =>
      list.first as Map<String, dynamic>,
    _ => null,
  };

  /// Admins only change account fields (e.g. status) here: they are written
  /// to `users`, then the merged row is read back via the embedded select.
  @override
  Future<UserModel> addOrUpdate(Map<String, dynamic> data, {String? id}) async {
    if (id == null) {
      throw ApiException('Accounts are created by signing up in the app.');
    }
    final payload = Map<String, dynamic>.from(data)..remove(JsonKeys.id);
    await client.from(DatabaseTables.users).update(payload).eq(JsonKeys.id, id);
    return _getListRow(id);
  }

  @override
  Future<List<UserModel>> updateMany(
    Map<String, dynamic> data,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final payload = Map<String, dynamic>.from(data)..remove(JsonKeys.id);
    await client
        .from(DatabaseTables.users)
        .update(payload)
        .inFilter(JsonKeys.id, ids);
    final rows = await client
        .from(tableName)
        .select(_listSelect)
        .inFilter(JsonKeys.id, ids);
    return rows.map((r) => UserModel.fromJson(_normalizeProfiles(r))).toList();
  }

  /// Deleting goes through delete_user (see [delete]) for every account.
  @override
  Future<void> deleteMany(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  Future<UserModel> _getListRow(String id) async {
    final row = await client
        .from(tableName)
        .select(_listSelect)
        .eq(JsonKeys.id, id)
        .maybeSingle();
    if (row == null) {
      throw ApiException(
        "Unable to get $entityName details. Please try again later.",
      );
    }
    return UserModel.fromJson(_normalizeProfiles(row));
  }

  // Approving / rejecting an application lives in UserReviewRepository
  // (admin-only RPCs that enforce the review rules).

  /// Blocks user account.
  Future<UserModel> blockUser(String id) async {
    await client
        .from(DatabaseTables.users)
        .update({JsonKeys.registrationStatus: UserStatus.blocked.apiValue})
        .eq(JsonKeys.id, id);

    return getDetails(id);
  }

  /// Unblocks user account to approved status.
  Future<UserModel> unblockUser(String id) async {
    await client
        .from(DatabaseTables.users)
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
