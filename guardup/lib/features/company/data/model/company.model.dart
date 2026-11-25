import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/string.extension.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '../enum/business_type.enum.dart';

part 'company.model.freezed.dart';
part 'company.model.g.dart';

/// Company profile (`public.companies`).
@freezed
abstract class CompanyModel with _$CompanyModel {
  const CompanyModel._();

  const factory CompanyModel({
    required String id,
    String? userId,
    String? companyName,
    @Default('') String name,
    String? businessEmail,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    BusinessType? companyType,
    @Default('+91') String companyPhoneCode,
    String? companyPhoneNumber,
    int? experienceYears,
    String? address,
    double? latitude,
    double? longitude,
    String? licenseNumber,
    @Default(UserStatus.active)
    @JsonKey(unknownEnumValue: UserStatus.active)
    UserStatus status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);

  String get displayName => companyName?.trim().isNotEmpty == true
      ? companyName!
      : (name.isNotEmpty ? name : 'Security Company');

  String get experienceYearsFormatted =>
      (experienceYears != null && experienceYears! > 0)
          ? '$experienceYears+ Yrs Exp'
          : '0 Yrs Exp';

  // UI display getters (non-persisted, pure presentation)
  String? get initials => companyName?.getInitials() ?? name.getInitials();
  String? get logoUrl => null;
  String? get bio => null;
  int get activeGuards => 12;
  double get rating => 0.0;
  int get reviewCount => 0;
  String get bookingsCount => '0 Bookings';
  bool get isVerified => true;
  bool get isOnline => true;
  DateTime? get joinedAt => createdAt;

  /// Sample fake security companies for UI mocking, feeds, and tests.
  static List<CompanyModel> get fakeData => [
    const CompanyModel(
      id: 'comp_securepro',
      companyName: 'SecurePro Security Ltd.',
      name: 'SecurePro Security Ltd.',
      experienceYears: 0,
    ),
    const CompanyModel(
      id: 'comp_aegis',
      companyName: 'Aegis Elite Tactical',
      name: 'Aegis Elite Tactical',
      experienceYears: 0,
    ),
    const CompanyModel(
      id: 'comp_ironclad',
      companyName: 'Ironclad Protection Group',
      name: 'Ironclad Protection Group',
      experienceYears: 0,
    ),
  ];
}
