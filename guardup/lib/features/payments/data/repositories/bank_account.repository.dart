import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/repositories/base.repository.dart';
import '../model/bank_account_request.model.dart';
import '../model/user_bank_account.model.dart';

/// `public.user_bank_accounts`: Saved payout bank accounts for users and guards.
final class BankAccountRepository
    extends BaseSupabaseRepository<UserBankAccountModel> {
  BankAccountRepository(SupabaseClient client)
    : super(
        client: client,
        tableName: DatabaseTables.userBankAccounts,
        fromJson: UserBankAccountModel.fromJson,
        entityName: 'bank account',
        searchFields: const [
          JsonKeys.bankName,
          JsonKeys.accountHolder,
          JsonKeys.accountNumber,
        ],
        primarySortColumn: JsonKeys.createdAt,
        primarySortAscending: false,
      );

  /// All bank accounts of [userId], primary account first, then newest.
  Future<List<UserBankAccountModel>> getAll(String userId) async {
    final rows = await client
        .from(tableName)
        .select()
        .eq(JsonKeys.userId, userId)
        .order(JsonKeys.isPrimary, ascending: false)
        .order(JsonKeys.createdAt, ascending: false);
    return (rows as List<dynamic>)
        .map((r) => UserBankAccountModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Adds a new bank account for [userId].
  Future<UserBankAccountModel> add(
    String userId,
    BankAccountRequest request,
  ) async {
    final row = await client
        .from(tableName)
        .insert(request.toJson(userId: userId))
        .select()
        .single();
    return UserBankAccountModel.fromJson(row);
  }

  /// Deletes account by [id].
  @override
  Future<void> delete(String id) async {
    await client.from(tableName).delete().eq(JsonKeys.id, id);
  }

  /// Sets account [id] as primary for [userId], clearing primary on others.
  Future<void> setPrimary(String userId, String id) async {
    await client
        .from(tableName)
        .update({JsonKeys.isPrimary: false})
        .eq(JsonKeys.userId, userId);

    await client
        .from(tableName)
        .update({JsonKeys.isPrimary: true})
        .eq(JsonKeys.id, id);
  }
}
