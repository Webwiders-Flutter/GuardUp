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

  /// Curated list of verified licenses matching the bodyguard documents mockup.
  static List<LicenseAndBadgeModel> get fakeData => [
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
      validTill: DateTime(2027, 6, 15),
      isVerified: true,
      icon: Icons.gps_fixed_rounded,
    ),
  ];
}
