import 'package:flutter/material.dart';

/// Represents a tactical bodyguard certification, operational license, or accredited badge.
class LicenseAndBadgeModel {
  final String id;
  final String name;
  final String description;
  final DateTime? validTill;
  final bool isVerified;
  final String? badgeNumber;
  final String? issuingAuthority;
  final String? customValidity;
  final IconData? icon;

  const LicenseAndBadgeModel({
    required this.id,
    required this.name,
    required this.description,
    this.validTill,
    this.isVerified = false,
    this.badgeNumber,
    this.issuingAuthority,
    this.customValidity,
    this.icon,
  });

  bool get isExpired {
    if (validTill == null) return false;
    return validTill!.isBefore(DateTime.now());
  }

  String get displayValidity {
    if (customValidity != null && customValidity!.isNotEmpty) {
      return customValidity!;
    }
    if (validTill == null) return 'Permanent / Lifetime';
    return '${validTill!.day.toString().padLeft(2, '0')}/${validTill!.month.toString().padLeft(2, '0')}/${validTill!.year}';
  }

  LicenseAndBadgeModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? validTill,
    bool? isVerified,
    String? badgeNumber,
    String? issuingAuthority,
  }) {
    return LicenseAndBadgeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      validTill: validTill ?? this.validTill,
      isVerified: isVerified ?? this.isVerified,
      badgeNumber: badgeNumber ?? this.badgeNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (validTill != null) 'validTill': validTill!.toIso8601String(),
      'isVerified': isVerified,
      if (badgeNumber != null) 'badgeNumber': badgeNumber,
      if (issuingAuthority != null) 'issuingAuthority': issuingAuthority,
    };
  }

  factory LicenseAndBadgeModel.fromJson(Map<String, dynamic> json) {
    return LicenseAndBadgeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      validTill: json['validTill'] != null
          ? DateTime.tryParse(json['validTill'] as String)
          : null,
      isVerified: json['isVerified'] as bool? ?? false,
      badgeNumber: json['badgeNumber'] as String?,
      issuingAuthority: json['issuingAuthority'] as String?,
    );
  }

  /// Curated list of verified licenses matching the bodyguard documents mockup.
  static List<LicenseAndBadgeModel> get fakeAuditedLicenses => [
    LicenseAndBadgeModel(
      id: 'lic_sia',
      name: 'SIA Close Protection License',
      description: 'Close protection specialist accreditation and threat mitigation.',
      issuingAuthority: 'Security Industry Authority',
      customValidity: 'Valid till Oct 2026',
      validTill: DateTime(2026, 10, 31),
      isVerified: true,
      icon: Icons.shield_outlined,
    ),
    LicenseAndBadgeModel(
      id: 'lic_cpr',
      name: 'Advanced CPR & First Aid',
      description: 'Emergency trauma life support, bleed management and resuscitation.',
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

