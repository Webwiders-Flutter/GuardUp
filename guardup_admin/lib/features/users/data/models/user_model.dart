import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/services/data/models/service.model.dart';
import '/features/users/data/enums/business_type.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import 'user_document.model.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

List<ServiceModel>? _serviceListFromJson(dynamic json) {
  if (json == null) return null;
  if (json is! List) return null;
  return json.map((e) {
    if (e is! Map<String, dynamic>) return null;
    final sMap = e['service'] is Map<String, dynamic>
        ? e['service'] as Map<String, dynamic>
        : e;
    return ServiceModel.fromJson(sMap);
  }).whereType<ServiceModel>().toList();
}

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String name,
    required String email,
    String? phoneNumber,
    @JsonKey(defaultValue: '+91') String? phoneCode,
    @Default(UserRoleType.customer)
    @JsonKey(unknownEnumValue: UserRoleType.customer)
    UserRoleType role,
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,
    String? profileImageUrl,
    double? hourlyRate,
    String? bio,
    @JsonKey(name: 'user_services', fromJson: _serviceListFromJson)
    List<ServiceModel>? serviceListData,
    double? rating,
    String? companyName,
    String? businessEmail,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BusinessType? companyType,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Joined / related documents
    List<UserDocumentModel>? documents,
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
