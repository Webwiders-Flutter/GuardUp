import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/users/data/enums/business_type.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import 'user_document.model.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'phone_code', defaultValue: '+91') String? phoneCode,
    @Default(UserRoleType.customer)
    @JsonKey(unknownEnumValue: UserRoleType.customer)
    UserRoleType role,
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @JsonKey(name: 'hourly_rate') double? hourlyRate,
    String? bio,
    List<String>? services,
    double? rating,
    @JsonKey(name: 'company_name') String? companyName,
    @JsonKey(name: 'business_email') String? businessEmail,
    @JsonKey(name: 'company_type', unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BusinessType? companyType,
    Map<String, dynamic>? metadata,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    // Joined / related documents
    List<UserDocumentModel>? documents,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Backward-compatible getters for UI & Admin Shell
  String get fullName => name.isNotEmpty ? name : (companyName ?? email);
  String get mobileNumber => phoneNumber ?? '';
  String? get businessName => companyName;
  UserStatus get registrationStatus => status;

  String get displayPhone {
    if (phoneNumber == null || phoneNumber!.isEmpty) return '—';
    final code = phoneCode?.isNotEmpty == true ? phoneCode! : '+91';
    return '$code $phoneNumber';
  }

  String get displayCompanyType => companyType?.label() ?? '—';

  bool get isApproved => status == UserStatus.active;
  bool get isPendingApproval => status == UserStatus.approvalPending;
  bool get isBlocked => status == UserStatus.blocked;
  bool get isCustomer => role == UserRoleType.customer;
  bool get isGuard => role == UserRoleType.guard;
  bool get isCompany => role == UserRoleType.company;
  bool get isAdmin => role == UserRoleType.admin;
}
