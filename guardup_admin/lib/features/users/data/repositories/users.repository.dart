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
          JsonKeys.phoneCode,
          JsonKeys.businessName,
          JsonKeys.businessEmail,
          JsonKeys.companyPhoneNumber,
          JsonKeys.companyPhoneCode,
        ],
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  @override
  String? buildSearchFilter(String queryStr) {
    final raw = queryStr.trim();
    if (raw.isEmpty) return null;

    final sanitizedRaw = raw.replaceAll('"', '');
    final filters = <String>{};

    // 1. Core Profile and Business text fields
    filters.add('${JsonKeys.fullName}.ilike."%$sanitizedRaw%"');
    filters.add('${JsonKeys.email}.ilike."%$sanitizedRaw%"');
    filters.add('${JsonKeys.businessName}.ilike."%$sanitizedRaw%"');
    filters.add('${JsonKeys.businessEmail}.ilike."%$sanitizedRaw%"');

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
    final splitBySeparatorMatch =
        RegExp(r'^\+?(\d{1,4})[\s\-./()]+(\d.*)$').firstMatch(raw);
    if (splitBySeparatorMatch != null) {
      final codeDigits = splitBySeparatorMatch.group(1)!;
      final numberPart =
          splitBySeparatorMatch.group(2)!.replaceAll(RegExp(r'\D'), '');
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
