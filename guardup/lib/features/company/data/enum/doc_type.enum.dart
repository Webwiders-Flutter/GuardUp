import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/gen/app_localizations.dart';

/// Represents the document types available across document upload and verification.
enum DocType {
  @JsonValue('BUSINESS_REGISTRATION')
  businessRegistration('BUSINESS_REGISTRATION'),

  @JsonValue('GOVERNMENT_ID')
  governmentId('GOVERNMENT_ID'),

  @JsonValue('COMPANY_LOGO')
  companyLogo('COMPANY_LOGO'),

  @JsonValue('ADDITIONAL_DOCUMENTS')
  additionalDocuments('ADDITIONAL_DOCUMENTS');

  final String apiValue;

  const DocType(this.apiValue);

  static DocType fromApiValue(String? value) {
    if (value == null) return DocType.businessRegistration;
    return DocType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => DocType.businessRegistration,
    );
  }

  static DocType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return DocType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case DocType.businessRegistration:
        return l10n.businessRegistration;
      case DocType.governmentId:
        return l10n.governmentIdAdmin;
      case DocType.companyLogo:
        return l10n.companyLogo;
      case DocType.additionalDocuments:
        return l10n.additionalDocuments;
    }
  }

  IconData get icon {
    switch (this) {
      case DocType.businessRegistration:
        return Icons.description_outlined;
      case DocType.governmentId:
        return Icons.badge_outlined;
      case DocType.companyLogo:
        return Icons.image_outlined;
      case DocType.additionalDocuments:
        return Icons.description_outlined;
    }
  }

  bool get allowFile {
    switch (this) {
      case DocType.companyLogo:
        return false;
      case DocType.businessRegistration:
      case DocType.governmentId:
      case DocType.additionalDocuments:
        return true;
    }
  }

  bool get allowCrop {
    switch (this) {
      case DocType.companyLogo:
        return true;
      case DocType.businessRegistration:
      case DocType.governmentId:
      case DocType.additionalDocuments:
        return false;
    }
  }
}

