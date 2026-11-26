import 'package:freezed_annotation/freezed_annotation.dart';

import '../fixtures/payments.fixtures.dart';

part 'bank_account.model.freezed.dart';
part 'bank_account.model.g.dart';

/// Model representing a user's or company's saved bank account.
@freezed
abstract class BankAccount with _$BankAccount {
  const factory BankAccount({
    required String id,
    required String accountNumber,
    required String accountHolder,
    required String bankName,
    required String branch,
    required String ifscCode,
    String? branchAddress,
  }) = _BankAccount;

  factory BankAccount.fromJson(Map<String, dynamic> json) =>
      _$BankAccountFromJson(json);

  factory BankAccount.fromSupabase(Map<String, dynamic> map) {
    return BankAccount(
      id: (map['id'] ?? '') as String,
      accountNumber: (map['account_number'] ?? '').toString(),
      accountHolder: (map['account_holder'] ?? '').toString(),
      bankName: (map['bank_name'] ?? '').toString(),
      branch: (map['branch'] ?? '').toString(),
      ifscCode: (map['ifsc_code'] ?? '').toString(),
      branchAddress: map['branch_address'] as String?,
    );
  }

  @Deprecated('Use bankAccountPlaceholders from data/fixtures/payments.fixtures.dart')
  static List<BankAccount> get fakeData => bankAccountPlaceholders;
}
