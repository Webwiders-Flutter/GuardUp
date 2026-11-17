import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Represents the document types available across document upload and verification.
enum CompanyDocType {
  @JsonValue('BUSINESS_REGISTRATION')
  businessRegistration('BUSINESS_REGISTRATION'),

  @JsonValue('GOVERNMENT_ID')
  governmentId('GOVERNMENT_ID'),

  @JsonValue('COMPANY_LOGO')
  companyLogo('COMPANY_LOGO'),

  @JsonValue('ADDITIONAL_DOCUMENTS')
  additionalDocuments('ADDITIONAL_DOCUMENTS');

  final String apiValue;

  const CompanyDocType(this.apiValue);

  static CompanyDocType fromApiValue(String? value) {
    if (value == null) return CompanyDocType.businessRegistration;
    return CompanyDocType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => CompanyDocType.businessRegistration,
    );
  }

  static CompanyDocType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return CompanyDocType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case CompanyDocType.businessRegistration:
        return l10n.businessRegistration;
      case CompanyDocType.governmentId:
        return l10n.governmentIdAdmin;
      case CompanyDocType.companyLogo:
        return l10n.companyLogo;
      case CompanyDocType.additionalDocuments:
        return l10n.additionalDocuments;
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case CompanyDocType.businessRegistration:
        return 'Certificate of Incorporation / Trade License';
      case CompanyDocType.governmentId:
        return 'Director / Authorized Signatory Govt ID';
      case CompanyDocType.companyLogo:
        return 'Official Company Logo (Square/PNG)';
      case CompanyDocType.additionalDocuments:
        return 'PSARA License / Security Certifications';
    }
  }

  bool get isRequired {
    switch (this) {
      case CompanyDocType.businessRegistration:
      case CompanyDocType.governmentId:
        return true;
      case CompanyDocType.companyLogo:
      case CompanyDocType.additionalDocuments:
        return false;
    }
  }

  bool get isOptional => !isRequired;

  IconData get icon {
    switch (this) {
      case CompanyDocType.businessRegistration:
        return Icons.description_outlined;
      case CompanyDocType.governmentId:
        return Icons.badge_outlined;
      case CompanyDocType.companyLogo:
        return Icons.image_outlined;
      case CompanyDocType.additionalDocuments:
        return Icons.description_outlined;
    }
  }

  bool get allowFile {
    switch (this) {
      case CompanyDocType.companyLogo:
        return false;
      case CompanyDocType.businessRegistration:
      case CompanyDocType.governmentId:
      case CompanyDocType.additionalDocuments:
        return true;
    }
  }

  bool get allowCrop {
    switch (this) {
      case CompanyDocType.companyLogo:
        return true;
      case CompanyDocType.businessRegistration:
      case CompanyDocType.governmentId:
      case CompanyDocType.additionalDocuments:
        return false;
    }
  }
}
