import 'package:freezed_annotation/freezed_annotation.dart';

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

/// Embedded `user_services(id, service:services(...))` rows as services.
List<ServiceModel>? _servicesFromJson(dynamic json) {
  if (json is! List) return null;
  return [
    for (final row in json)
      if (row is Map<String, dynamic>)
        if (row['service'] is Map<String, dynamic>)
          ServiceModel.fromJson(row['service'] as Map<String, dynamic>)
        else
          ServiceModel.fromJson(row),
  ];
}

BodyGuardModel? _bodyguardFromJson(dynamic json) {
  if (json == null) return null;
  if (json is BodyGuardModel) return json;
  if (json is Map<String, dynamic>) return BodyGuardModel.fromJson(json);
  if (json is List && json.isNotEmpty && json.first is Map<String, dynamic>) {
    return BodyGuardModel.fromJson(json.first as Map<String, dynamic>);
  }
  return null;
}

CompanyModel? _companyFromJson(dynamic json) {
  if (json == null) return null;
  if (json is CompanyModel) return json;
  if (json is Map<String, dynamic>) return CompanyModel.fromJson(json);
  if (json is List && json.isNotEmpty && json.first is Map<String, dynamic>) {
    return CompanyModel.fromJson(json.first as Map<String, dynamic>);
  }
  return null;
}

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
      fromJson: _servicesFromJson,
      includeToJson: false,
    )
    List<ServiceModel>? serviceListData,
    @JsonKey(includeToJson: false) List<UserDocumentModel>? documents,
    @JsonKey(includeToJson: false) List<BankAccount>? bankAccounts,
    @JsonKey(includeToJson: false) List<UserAvailabilityModel>? availabilities,
  }) = _UserModel;

  /// Creates a [UserModel] for request payloads (omitting the server-generated [id]).
  factory UserModel.fromRequest({
    required String name,
    String? email,
    String? phoneNumber,
    String phoneCode = '+91',
    String? profileImageUrl,
    UserRole? role,
    UserStatus? status,
    GenderType? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
    id: '',
    name: name,
    email: email ?? '',
    phoneNumber: phoneNumber,
    phoneCode: phoneCode,
    profileImageUrl: profileImageUrl,
    role: role ?? UserRole.customer,
    status: status ?? UserStatus.incomplete,
    gender: gender,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  static List<UserModel> get fakeData => const [
    UserModel(
      id: 'usr_vikram',
      name: 'Vikram Singh',
      role: UserRole.guard,
    ),
    UserModel(
      id: 'usr_marcus',
      name: 'Marcus Sterling',
      role: UserRole.guard,
    ),
    UserModel(
      id: 'usr_customer_1',
      name: 'Sara Khan',
      role: UserRole.customer,
    ),
  ];
}
