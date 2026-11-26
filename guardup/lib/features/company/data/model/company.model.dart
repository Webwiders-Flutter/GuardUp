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

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    final model = _$CompanyModelFromJson(json);
    // If name is empty, fallback to company_name
    final resolvedName = model.name.isNotEmpty
        ? model.name
        : (model.companyName?.trim().isNotEmpty == true
            ? model.companyName!.trim()
            : (json['company_name'] as String? ?? ''));
    if (resolvedName.isNotEmpty && model.name != resolvedName) {
      return model.copyWith(
        name: resolvedName,
        companyName: model.companyName ?? resolvedName,
      );
    }
    return model;
  }

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
      id: '00000000-0000-0000-0000-000000000001',
      companyName: 'SecurePro Security Ltd.',
      name: 'SecurePro Security Ltd.',
      experienceYears: 0,
    ),
    const CompanyModel(
      id: '00000000-0000-0000-0000-000000000002',
      companyName: 'Aegis Elite Tactical',
      name: 'Aegis Elite Tactical',
      experienceYears: 0,
    ),
    const CompanyModel(
      id: '00000000-0000-0000-0000-000000000003',
      companyName: 'Ironclad Protection Group',
      name: 'Ironclad Protection Group',
      experienceYears: 0,
    ),
  ];
}
