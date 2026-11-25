import 'package:freezed_annotation/freezed_annotation.dart';

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

    // UI and Display helpers
    String? initials,
    String? logoUrl,
    String? bio,
    @Default(12) int activeGuards,
    @Default(4.9) double rating,
    @Default(214) int reviewCount,
    @Default('0 Bookings') String bookingsCount,
    @Default(true) bool isVerified,
    @Default(true) bool isOnline,
    DateTime? joinedAt,
  }) = _CompanyModel;

  factory CompanyModel.fromJson(Map<String, dynamic> json) =>
      _$CompanyModelFromJson(json);

  String get displayName => companyName?.trim().isNotEmpty == true
      ? companyName!
      : (name.isNotEmpty ? name : 'Security Company');

  String get experienceYearsFormatted =>
      '${experienceYears ?? 0}+ Yrs Exp';

  /// Sample fake security companies for UI mocking, feeds, and tests.
  static List<CompanyModel> get fakeData => [
    const CompanyModel(
      id: 'comp_securepro',
      companyName: 'SecurePro Security Ltd.',
      name: 'SecurePro Security Ltd.',
      initials: 'SP',
      activeGuards: 12,
      rating: 4.9,
      reviewCount: 254,
      bookingsCount: '0 Bookings',
      experienceYears: 15,
      isVerified: true,
      isOnline: true,
    ),
    const CompanyModel(
      id: 'comp_aegis',
      companyName: 'Aegis Elite Tactical',
      name: 'Aegis Elite Tactical',
      initials: 'AE',
      activeGuards: 8,
      rating: 4.98,
      reviewCount: 180,
      bookingsCount: '0 Bookings',
      experienceYears: 22,
      isVerified: true,
      isOnline: true,
    ),
    const CompanyModel(
      id: 'comp_ironclad',
      companyName: 'Ironclad Protection Group',
      name: 'Ironclad Protection Group',
      initials: 'IP',
      activeGuards: 16,
      rating: 4.85,
      reviewCount: 310,
      bookingsCount: '0 Bookings',
      experienceYears: 18,
      isVerified: true,
      isOnline: true,
    ),
  ];
}
