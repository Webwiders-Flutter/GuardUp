import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/json_converters.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/features/services/data/models/service.model.dart';
import '/features/body_guard/data/model/user_availability.model.dart';
import '/features/body_guard/data/model/user_document.model.dart';
import '/features/company/data/model/company.model.dart';
import '/features/payments/data/model/bank_account.model.dart';
import '../enum/gender_type.enum.dart';
import '../enum/user_role.enum.dart';
import '../enum/user_status.enum.dart';

part 'user.model.freezed.dart';
part 'user.model.g.dart';

BodyGuardModel? _bodyguardFromJson(dynamic json) =>
    EmbeddedParser.parseObject(json, BodyGuardModel.fromJson);

CompanyModel? _companyFromJson(dynamic json) =>
    EmbeddedParser.parseObject(json, CompanyModel.fromJson);

List<UserDocumentModel>? _documentsFromJson(dynamic json) =>
    EmbeddedParser.parseList(json, UserDocumentModel.fromJson);

List<BankAccount>? _bankAccountsFromJson(dynamic json) =>
    EmbeddedParser.parseList(json, BankAccount.fromJson);

List<UserAvailabilityModel>? _availabilitiesFromJson(dynamic json) =>
    EmbeddedParser.parseList(json, UserAvailabilityModel.fromJson);

/// A login account (`public.users`): customer, guard, company, admin.
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    @Default('') String email,
    String? phoneNumber,
    @Default('+91') String phoneCode,
    @Default(UserRole.customer)
    @JsonKey(unknownEnumValue: UserRole.customer)
    UserRole role,
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,
    String? rejectionReason,
    String? profileImageUrl,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GenderType? gender,
    @Default(true) bool isPushNotificationEnabled,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,

    // Role profiles (joined embeds from companies / bodyguards)
    @JsonKey(fromJson: _companyFromJson, includeToJson: false)
    CompanyModel? company,
    @JsonKey(fromJson: _bodyguardFromJson, includeToJson: false)
    BodyGuardModel? bodyguard,

    // Embedded relations
    @JsonKey(
      name: 'user_services',
      fromJson: servicesFromUserServices,
      includeToJson: false,
    )
    List<ServiceModel>? serviceListData,
    @JsonKey(fromJson: _documentsFromJson, includeToJson: false)
    List<UserDocumentModel>? documents,
    @JsonKey(fromJson: _bankAccountsFromJson, includeToJson: false)
    List<BankAccount>? bankAccounts,
    @JsonKey(fromJson: _availabilitiesFromJson, includeToJson: false)
    List<UserAvailabilityModel>? availabilities,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
