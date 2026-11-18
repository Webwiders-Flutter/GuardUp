import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_bank_account.model.freezed.dart';
part 'user_bank_account.model.g.dart';

/// One row of `user_bank_accounts`: a guard's / company's payout account.
/// Read-only in the admin panel.
@freezed
abstract class UserBankAccountModel with _$UserBankAccountModel {
  const factory UserBankAccountModel({
    required String id,
    required String userId,
    required String accountNumber,
    required String accountHolder,
    required String bankName,
    required String branch,
    required String ifscCode,
    String? branchAddress,
    @Default(true) bool isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserBankAccountModel;

  factory UserBankAccountModel.fromJson(Map<String, dynamic> json) =>
      _$UserBankAccountModelFromJson(json);
}
