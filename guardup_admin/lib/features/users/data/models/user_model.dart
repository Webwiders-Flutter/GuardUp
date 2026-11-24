import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/services/data/models/service.model.dart';
import '/features/users/data/enums/gender_type.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import 'bodyguard.model.dart';
import 'company.model.dart';
import 'user_availability.model.dart';
import 'user_bank_account.model.dart';
import 'user_document.model.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Embedded `user_services(id, service:services(...))` rows as services.
List<ServiceModel>? _servicesFromJson(dynamic json) {
  if (json is! List) return null;
  return [
    for (final row in json)
      if (row is Map<String, dynamic> && row['service'] is Map<String, dynamic>)
        ServiceModel.fromJson(row['service'] as Map<String, dynamic>),
  ];
}

/// A login account (`public.users`): every role.
///
/// The role profile is a separate model, set by role:
/// - COMPANY: [company] (`public.companies`)
/// - GUARD: [bodyguard] (`public.bodyguards`, self-registered)
/// - CUSTOMER / ADMIN: none (a customer has no profile table; the account is
///   the customer)
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    String? phoneNumber,
    @Default('+91') String phoneCode,
    @Default(UserRoleType.customer)
    @JsonKey(unknownEnumValue: UserRoleType.customer)
    UserRoleType role,
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,

    /// Why an admin rejected the profile (set only for a profile rejection;
    /// document reasons live on each [UserDocumentModel]).
    String? rejectionReason,
    String? profileImageUrl,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GenderType? gender,
    String? address,
    double? latitude,
    double? longitude,
    @Default(true) bool isPushNotificationEnabled,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,

    // Role profiles (`user_profiles` view columns / details query embeds)
    CompanyModel? company,
    BodyguardModel? bodyguard,

    // Embedded relations of the account (details query only; see UsersRepository)
    @JsonKey(
      name: 'user_services',
      fromJson: _servicesFromJson,
      includeToJson: false,
    )
    List<ServiceModel>? serviceListData,
    List<UserDocumentModel>? documents,
    List<UserBankAccountModel>? bankAccounts,
    List<UserAvailabilityModel>? availabilities,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
