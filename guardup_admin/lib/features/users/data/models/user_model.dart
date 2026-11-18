import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/services/data/models/service.model.dart';
import '/features/users/data/enums/business_type.enum.dart';
import '/features/users/data/enums/gender_type.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import 'user_availability.model.dart';
import 'user_bank_account.model.dart';
import 'user_document.model.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

List<ServiceModel>? _serviceListFromJson(dynamic json) {
  if (json == null) return null;
  if (json is! List) return null;
  return json
      .map((e) {
        if (e is! Map<String, dynamic>) return null;
        final sMap = e['service'] is Map<String, dynamic>
            ? e['service'] as Map<String, dynamic>
            : e;
        return ServiceModel.fromJson(sMap);
      })
      .whereType<ServiceModel>()
      .toList();
}

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

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

    // Bodyguard profile
    double? hourlyRate,
    String? bio,
    int? experienceYears,

    /// Free text, comma separated (e.g. "English, Hindi").
    String? languages,

    /// Free text, comma separated (e.g. "CPR, First Aid").
    String? certifications,
    @JsonKey(name: 'user_services', fromJson: _serviceListFromJson)
    List<ServiceModel>? serviceListData,
    double? rating,

    // Company profile
    String? companyName,
    String? businessEmail,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BusinessType? companyType,
    @Default('+91') String companyPhoneCode,
    String? companyPhoneNumber,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Embedded relations (details query only; see UsersRepository)
    List<UserDocumentModel>? documents,
    List<UserBankAccountModel>? bankAccounts,
    List<UserAvailabilityModel>? availabilities,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Backward-compatible services list as strings
  List<String> get services =>
      serviceListData?.map((s) => s.name).where((n) => n.isNotEmpty).toList() ??
      const [];

  // Backward-compatible getters for UI & Admin Shell
  String get fullName => name.isNotEmpty ? name : (companyName ?? email);
  String get mobileNumber => phoneNumber ?? '';
  String? get businessName => companyName;
}
