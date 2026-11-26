import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_bank_account.model.freezed.dart';
part 'user_bank_account.model.g.dart';

/// One row of `public.user_bank_accounts`: payout account.
@freezed
abstract class UserBankAccountModel with _$UserBankAccountModel {
  const factory UserBankAccountModel({
    required String id,
    @Default('') @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'account_holder') required String accountHolder,
    @JsonKey(name: 'bank_name') required String bankName,
    required String branch,
    @JsonKey(name: 'ifsc_code') required String ifscCode,
    @JsonKey(name: 'branch_address') String? branchAddress,
    @Default(true) @JsonKey(name: 'is_primary') bool isPrimary,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserBankAccountModel;

  factory UserBankAccountModel.fromJson(Map<String, dynamic> json) =>
      _$UserBankAccountModelFromJson(json);

  factory UserBankAccountModel.fromSupabase(Map<String, dynamic> map) =>
      UserBankAccountModel.fromJson(map);
}
