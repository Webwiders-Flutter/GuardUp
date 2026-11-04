import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'license_and_badge.model.freezed.dart';
part 'license_and_badge.model.g.dart';

/// Represents a tactical bodyguard certification, operational license, or accredited badge.
@freezed
abstract class LicenseAndBadgeModel with _$LicenseAndBadgeModel {
  const factory LicenseAndBadgeModel({
    required String id,
    required String name,
    required String description,
    DateTime? validTill,
    @Default(false) bool isVerified,
    String? badgeNumber,
    String? issuingAuthority,
    String? customValidity,
    @JsonKey(includeFromJson: false, includeToJson: false) IconData? icon,
  }) = _LicenseAndBadgeModel;

  factory LicenseAndBadgeModel.fromJson(Map<String, dynamic> json) =>
      _$LicenseAndBadgeModelFromJson(json);

  static List<LicenseAndBadgeModel> get fakeData => fakeAuditedLicenses;

  /// Curated list of verified licenses matching the bodyguard documents mockup.
  static List<LicenseAndBadgeModel> get fakeAuditedLicenses => [
    LicenseAndBadgeModel(
      id: 'lic_sia',
      name: 'SIA Close Protection License',
      description:
          'Close protection specialist accreditation and threat mitigation.',
      issuingAuthority: 'Security Industry Authority',
      customValidity: 'Valid till Oct 2026',
      validTill: DateTime(2026, 10, 31),
      isVerified: true,
      icon: Icons.shield_outlined,
    ),
    LicenseAndBadgeModel(
      id: 'lic_cpr',
      name: 'Advanced CPR & First Aid',
      description:
          'Emergency trauma life support, bleed management and resuscitation.',
      issuingAuthority: 'St. John Ambulance',
      customValidity: 'Valid till Nov 2025',
      validTill: DateTime(2025, 11, 30),
      isVerified: true,
      icon: Icons.favorite_border_rounded,
    ),
    LicenseAndBadgeModel(
      id: 'lic_driving',
      name: 'Tactical Evasive Driving',
      description: 'High-speed motorcade tactical driving, skid recovery, and PIT avoidance.',
      issuingAuthority: 'Precision Institute',
      customValidity: 'Certified',
      isVerified: true,
      icon: Icons.gps_fixed_rounded,
    ),
  ];

  /// Curated list of elite bodyguard licenses and certifications.
  static List<LicenseAndBadgeModel> get fakeLicensesAndBadges => [
    LicenseAndBadgeModel(
      id: 'lic_1',
      name: 'Armed Executive Protection License',
      description: 'Federal Class-A certification for armed dignitary escort and counter-ambush tactics.',
      validTill: DateTime(2028, 12, 31),
      isVerified: true,
      badgeNumber: 'GUARD-EP-9942',
      issuingAuthority: 'Security & Intelligence Directorate',
    ),
    LicenseAndBadgeModel(
      id: 'lic_2',
      name: 'Tactical Defensive Driving (B6 Armored)',
      description: 'Certified evasive maneuver specialist for heavy armored transport Cadillac & Suburban units.',
      validTill: DateTime(2027, 6, 15),
      isVerified: true,
      badgeNumber: 'DRV-ARM-4081',
      issuingAuthority: 'Tactical Mobility Institute',
    ),
    LicenseAndBadgeModel(
      id: 'lic_3',
      name: 'Trauma First Responder & CPR Level 3',
      description: 'Field medical response for ballistics, severe bleeding control, and automated external defibrillator operation.',
      validTill: DateTime(2029, 3, 20),
      isVerified: true,
      badgeNumber: 'MED-TCCC-719',
      issuingAuthority: 'International Emergency Care Council',
    ),
    LicenseAndBadgeModel(
      id: 'lic_4',
      name: 'Concealed Firearms Carry Permit (CCW)',
      description: 'Statewide multi-jurisdictional concealed carry endorsement for high-risk details.',
      validTill: DateTime(2027, 11, 10),
      isVerified: true,
      badgeNumber: 'CCW-X8832',
      issuingAuthority: 'State Law Enforcement Bureau',
    ),
  ];
}
