import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/json_converters.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '../enum/business_type.enum.dart';

export '/core/extensions/company.extension.dart';

part 'company.model.freezed.dart';
part 'company.model.g.dart';

CompanyUserSummary? _userFromJson(dynamic json) =>
    EmbeddedParser.parseObject(json, CompanyUserSummary.fromJson);

/// Company profile of a COMPANY account (`public.companies`, one per
/// account), 1:1 with the table. Account data (name, status, photo) stays on
/// `users`; [user] carries the embedded summary when the select includes it.
///
/// Display helpers live in `CompanyModelX` (core/extensions).
@freezed
abstract class CompanyModel with _$CompanyModel {
  const factory CompanyModel({
    required String id,
    String? userId,
    String? companyName,
    String? businessEmail,

    /// Stored as the `BusinessType` API value (`PVT_LTD`, …).
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BusinessType? companyType,
    @Default('+91') String companyPhoneCode,
    String? companyPhoneNumber,

    /// Years in operation.
    @NullableIntConverter() int? experienceYears,
    DateTime? createdAt,
    DateTime? updatedAt,

    /// `user:users!companies_user_id_fkey(...)` embed (see CompanyRepository).
    @JsonKey(fromJson: _userFromJson, includeToJson: false)
    CompanyUserSummary? user,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);
}

/// The few `users` columns embedded with a company.
@freezed
abstract class CompanyUserSummary with _$CompanyUserSummary {
  const factory CompanyUserSummary({
    required String id,
    @Default('') String name,
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,
    String? profileImageUrl,
  }) = _CompanyUserSummary;

  factory CompanyUserSummary.fromJson(Map<String, dynamic> json) =>
      _$CompanyUserSummaryFromJson(json);
}
