import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Represents document types for bodyguard credential verification.
enum GuardDocType {
  @JsonValue('ID_PROOF')
  idProof('ID_PROOF'),

  @JsonValue('POLICE_VERIFICATION')
  policeVerification('POLICE_VERIFICATION'),

  @JsonValue('SECURITY_LICENSE')
  securityLicense('SECURITY_LICENSE'),

  @JsonValue('CERTIFICATIONS')
  certifications('CERTIFICATIONS');

  final String apiValue;

  const GuardDocType(this.apiValue);

  static GuardDocType fromApiValue(String? value) {
    if (value == null) return GuardDocType.idProof;
    return GuardDocType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => GuardDocType.idProof,
    );
  }

  static GuardDocType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return GuardDocType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case GuardDocType.idProof:
        return 'ID Proof';
      case GuardDocType.policeVerification:
        return 'Police Verification';
      case GuardDocType.securityLicense:
        return 'Security License';
      case GuardDocType.certifications:
        return 'Certifications';
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case GuardDocType.idProof:
        return 'Aadhaar / Passport / SSN';
      case GuardDocType.policeVerification:
        return 'Clearance Certificate';
      case GuardDocType.securityLicense:
        return 'Armed / Unarmed Guard ID';
      case GuardDocType.certifications:
        return 'First Aid / Tactical Defense';
    }
  }

  IconData get icon {
    switch (this) {
      case GuardDocType.idProof:
        return Icons.badge_outlined;
      case GuardDocType.policeVerification:
        return Icons.verified_user_outlined;
      case GuardDocType.securityLicense:
        return Icons.lock_outline_rounded;
      case GuardDocType.certifications:
        return Icons.military_tech_outlined;
    }
  }

  bool get isRequired {
    switch (this) {
      case GuardDocType.idProof:
      case GuardDocType.policeVerification:
      case GuardDocType.securityLicense:
        return true;
      case GuardDocType.certifications:
        return false;
    }
  }

  bool get isOptional => !isRequired;
}
