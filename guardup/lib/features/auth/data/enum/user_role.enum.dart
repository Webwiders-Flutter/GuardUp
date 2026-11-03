import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/extensions/context.extension.dart';
import '/gen/app_localizations.dart';
import '/gen/assets.gen.dart';

/// Represents the user role chosen during onboarding or registration.
enum UserRole {
  @JsonValue('CUSTOMER')
  customer('CUSTOMER'),

  @JsonValue('GUARD')
  guard('GUARD'),

  @JsonValue('COMPANY')
  company('COMPANY');

  final String apiValue;

  const UserRole(this.apiValue);

  static UserRole fromApiValue(String? value) {
    if (value == null) return UserRole.customer;
    return UserRole.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => UserRole.customer,
    );
  }

  static UserRole? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return UserRole.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case UserRole.customer:
        return l10n.roleCustomer;
      case UserRole.guard:
        return l10n.roleGuard;
      case UserRole.company:
        return l10n.roleCompany;
    }
  }

  String longLabel(AppLocalizations l10n) {
    switch (this) {
      case UserRole.customer:
        return l10n.roleCustomerLong;
      case UserRole.guard:
        return l10n.roleGuardLong;
      case UserRole.company:
        return l10n.roleCompanyLong;
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case UserRole.customer:
        return l10n.roleCustomerDesc;
      case UserRole.guard:
        return l10n.roleGuardDesc;
      case UserRole.company:
        return l10n.roleCompanyDesc;
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case UserRole.customer:
        return colors.primary;
      case UserRole.guard:
        return colors.primary;
      case UserRole.company:
        return colors.primary;
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.customer:
        return Icons.person_outline_rounded;
      case UserRole.guard:
        return Icons.security_rounded;
      case UserRole.company:
        return Icons.business_rounded;
    }
  }

  String get svgPath {
    switch (this) {
      case UserRole.customer:
        return Assets.svg.user.path;
      case UserRole.guard:
        return Assets.svg.businessman.path;
      case UserRole.company:
        return Assets.svg.building.path;
    }
  }
}
