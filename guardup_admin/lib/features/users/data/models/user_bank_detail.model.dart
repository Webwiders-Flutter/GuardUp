import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/users/data/enums/verification_status.enum.dart';

part 'user_bank_detail.model.freezed.dart';
part 'user_bank_detail.model.g.dart';

@freezed
abstract class UserBankDetailModel with _$UserBankDetailModel {
  const factory UserBankDetailModel({
    String? id,
    required String userId,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    @Default(true) bool isPrimary,

    @Default(VerificationStatus.pending)
    @JsonKey(unknownEnumValue: VerificationStatus.pending)
    VerificationStatus verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserBankDetailModel;

  factory UserBankDetailModel.fromJson(Map<String, dynamic> json) =>
      _$UserBankDetailModelFromJson(json);
}
