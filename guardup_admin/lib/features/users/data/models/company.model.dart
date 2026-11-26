import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/users/data/enums/business_type.enum.dart';

part 'company.model.freezed.dart';
part 'company.model.g.dart';

/// Company profile of a COMPANY account (`public.companies`, one per account).
/// Account data (name, email, status ...) stays on [UserModel].
@freezed
abstract class CompanyModel with _$CompanyModel {
  const factory CompanyModel({
    required String id,
    required String userId,
    String? companyName,
    String? businessEmail,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BusinessType? companyType,
    @Default('+91') String companyPhoneCode,
    String? companyPhoneNumber,

    /// Years in operation.
    int? experienceYears,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);
}
