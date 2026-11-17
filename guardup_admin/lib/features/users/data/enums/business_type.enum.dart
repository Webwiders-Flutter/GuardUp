import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';
import '/gen/app_localizations.dart';

/// Enum representing business types for company registration.
enum BusinessType {
  @JsonValue('PROPRIETORSHIP')
  proprietorship('PROPRIETORSHIP'),

  @JsonValue('PARTNERSHIP')
  partnership('PARTNERSHIP'),

  @JsonValue('PVT_LTD')
  pvtLtd('PVT_LTD'),

  @JsonValue('PUBLIC_LTD')
  publicLtd('PUBLIC_LTD'),

  @JsonValue('LLP')
  llp('LLP'),

  @JsonValue('INDIVIDUAL')
  individual('INDIVIDUAL');

  final String apiValue;

  const BusinessType(this.apiValue);

  String label([AppLocalizations? l10n]) {
    switch (this) {
      case BusinessType.proprietorship:
        return 'Proprietorship';
      case BusinessType.partnership:
        return 'Partnership';
      case BusinessType.pvtLtd:
        return 'Private Limited (Pvt Ltd)';
      case BusinessType.publicLtd:
        return 'Public Limited';
      case BusinessType.llp:
        return 'Limited Liability Partnership (LLP)';
      case BusinessType.individual:
        return 'Individual';
    }
  }

  static BusinessType fromApiValue(String? value) {
    if (value == null) return BusinessType.proprietorship;
    return BusinessType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => BusinessType.proprietorship,
    );
  }

  static BusinessType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return BusinessType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case BusinessType.proprietorship:
      case BusinessType.partnership:
        return colors.info;
      case BusinessType.pvtLtd:
      case BusinessType.publicLtd:
        return colors.primary;
      case BusinessType.llp:
        return colors.secondary;
      case BusinessType.individual:
        return colors.warning;
    }
  }

  IconData get icon {
    switch (this) {
      case BusinessType.proprietorship:
        return Icons.person_pin_outlined;
      case BusinessType.partnership:
        return Icons.handshake_outlined;
      case BusinessType.pvtLtd:
        return Icons.business_rounded;
      case BusinessType.publicLtd:
        return Icons.corporate_fare_rounded;
      case BusinessType.llp:
        return Icons.apartment_rounded;
      case BusinessType.individual:
        return Icons.person_outline_rounded;
    }
  }
}

